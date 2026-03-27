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

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
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
            guard !jsonStr.isEmpty,
                  let data = jsonStr.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = event["type"] as? String else { continue }

            if type == "content_block_delta",
               let delta = event["delta"] as? [String: Any],
               let text = delta["text"] as? String {
                accumulated += text
            } else if type == "error" {
                let msg = (event["error"] as? [String: Any])?["message"] as? String ?? "Stream error"
                throw AIServiceError.serverError(0, msg)
            }
        }

        return accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
