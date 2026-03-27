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
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": text]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse("Not an HTTP response")
        }

        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimited
        }

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
