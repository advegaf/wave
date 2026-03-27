import Foundation

final class DeepgramProvider: TranscriptionProvider {
    let name = "Deepgram Nova-2"
    let providerType: TranscriptionProviderType = .deepgram

    private let keychainManager = KeychainManager.shared

    func transcribe(audioData: Data, format: AudioFormat) async throws -> String {
        guard let apiKey = try keychainManager.getDeepgramKey() else {
            throw AIServiceError.noAPIKey("Deepgram")
        }

        let url = URL(string: "https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true&language=en")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse("Not an HTTP response")
        }

        if httpResponse.statusCode == 429 {
            throw AIServiceError.rateLimited
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.serverError(httpResponse.statusCode, body)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let results = json?["results"] as? [String: Any],
              let channels = results["channels"] as? [[String: Any]],
              let alternatives = channels.first?["alternatives"] as? [[String: Any]],
              let transcript = alternatives.first?["transcript"] as? String else {
            throw AIServiceError.invalidResponse("Could not parse Deepgram response")
        }

        return transcript
    }
}
