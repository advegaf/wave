import Foundation

final class ClaudeProvider: RewriteProvider {
    let name = "Claude Haiku 4.5"
    let providerType: RewriteProviderType = .claude

    private let keychainManager = KeychainManager.shared
    private let model = "claude-haiku-4-5-20251001"

    func rewrite(text: String, context: RewriteContext) async throws -> String {
        guard let apiKey = try keychainManager.getAnthropicKey() else {
            throw AIServiceError.noAPIKey("Anthropic")
        }

        let systemPrompt = PromptBuilder.buildSystemPrompt(for: context)

        // Try streaming first, fall back to batch if streaming returns empty
        do {
            let result = try await rewriteStreaming(text: text, apiKey: apiKey, systemPrompt: systemPrompt)
            if !result.isEmpty {
                return result
            }
            print("[Wave] Claude streaming returned empty — falling back to batch")
        } catch {
            print("[Wave] Claude streaming failed: \(error) — falling back to batch")
        }

        return try await rewriteBatch(text: text, apiKey: apiKey, systemPrompt: systemPrompt)
    }

    // MARK: - Streaming (faster, SSE)

    private func rewriteStreaming(text: String, apiKey: String, systemPrompt: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "stream": true,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "<dictated_text>\n\(text)\n</dictated_text>\n\nClean the dictated text above. Return ONLY the cleaned version, nothing else."]
            ]
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
            guard !jsonStr.isEmpty,
                  let data = jsonStr.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = event["type"] as? String else { continue }

            if type == "content_block_delta",
               let delta = event["delta"] as? [String: Any],
               let deltaText = delta["text"] as? String {
                accumulated += deltaText
            } else if type == "error" {
                let msg = (event["error"] as? [String: Any])?["message"] as? String ?? "Stream error"
                throw AIServiceError.serverError(0, msg)
            }
        }

        return accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Batch (reliable fallback)

    private func rewriteBatch(text: String, apiKey: String, systemPrompt: String) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "<dictated_text>\n\(text)\n</dictated_text>\n\nClean the dictated text above. Return ONLY the cleaned version, nothing else."]
            ]
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
        guard let content = json?["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let rewrittenText = firstBlock["text"] as? String else {
            throw AIServiceError.invalidResponse("Could not parse Claude response")
        }

        return rewrittenText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
