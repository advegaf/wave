import Foundation

final class GPTProvider: RewriteProvider {
    let name = "GPT-4o"
    let providerType: RewriteProviderType = .gpt

    private let keychainManager = KeychainManager.shared
    private let model = "gpt-4o"

    func rewrite(text: String, context: RewriteContext) async throws -> String {
        guard let apiKey = try keychainManager.getOpenAIKey() else {
            throw AIServiceError.noAPIKey("OpenAI")
        }

        let systemPrompt = PromptBuilder.buildSystemPrompt(for: context)

        // Try streaming first, fall back to batch if streaming returns empty
        do {
            let result = try await rewriteStreaming(text: text, apiKey: apiKey, systemPrompt: systemPrompt)
            if !result.isEmpty {
                return result
            }
            print("[Wave] GPT streaming returned empty — falling back to batch")
        } catch {
            print("[Wave] GPT streaming failed: \(error) — falling back to batch")
        }

        return try await rewriteBatch(text: text, apiKey: apiKey, systemPrompt: systemPrompt)
    }

    // MARK: - Streaming (faster, SSE)

    private func rewriteStreaming(text: String, apiKey: String, systemPrompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "<dictated_text>\n\(text)\n</dictated_text>\n\nClean the dictated text above. Return ONLY the cleaned version, nothing else."]
            ],
            "max_tokens": 4096,
            "temperature": 0.3,
            "stream": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse("Not an HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 { throw AIServiceError.rateLimited }
            throw AIServiceError.serverError(httpResponse.statusCode, "HTTP \(httpResponse.statusCode)")
        }

        var accumulated = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            guard jsonStr != "[DONE]",
                  let data = jsonStr.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = event["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any],
                  let content = delta["content"] as? String else { continue }
            accumulated += content
        }

        return accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Batch (reliable fallback)

    private func rewriteBatch(text: String, apiKey: String, systemPrompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "<dictated_text>\n\(text)\n</dictated_text>\n\nClean the dictated text above. Return ONLY the cleaned version, nothing else."]
            ],
            "max_tokens": 4096,
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse("Not an HTTP response")
        }

        if httpResponse.statusCode == 429 { throw AIServiceError.rateLimited }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.serverError(httpResponse.statusCode, errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse("Could not parse GPT response")
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
