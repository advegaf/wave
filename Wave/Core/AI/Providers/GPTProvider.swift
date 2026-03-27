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

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
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

        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
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
}
