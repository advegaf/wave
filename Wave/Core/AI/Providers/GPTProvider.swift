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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 4096,
            "temperature": 0.3
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
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse("Could not parse GPT response")
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
