import Foundation

final class TranscriptionService {
    private var providers: [TranscriptionProviderType: TranscriptionProvider] = [:]

    func registerProvider(_ provider: TranscriptionProvider) {
        providers[provider.providerType] = provider
    }

    func transcribe(audioData: Data, format: AudioFormat = .pcm16kMono, using providerType: TranscriptionProviderType) async throws -> String {
        guard let provider = providers[providerType] else {
            throw AIServiceError.noAPIKey(providerType.rawValue)
        }
        return try await provider.transcribe(audioData: audioData, format: format)
    }
}
