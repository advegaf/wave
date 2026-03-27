import Foundation

// MARK: - Transcription

struct AudioFormat {
    let sampleRate: Int
    let channels: Int
    let bitsPerSample: Int

    static let pcm16kMono = AudioFormat(sampleRate: 16000, channels: 1, bitsPerSample: 16)
}

struct TranscriptionSegment {
    let text: String
    let isFinal: Bool
    let confidence: Double?
}

protocol TranscriptionProvider {
    var name: String { get }
    var providerType: TranscriptionProviderType { get }

    /// Batch transcription: send all audio at once, get back full text
    func transcribe(audioData: Data, format: AudioFormat) async throws -> String
}

protocol StreamingTranscriptionProvider: TranscriptionProvider {
    /// Start a streaming session
    func startStreaming(format: AudioFormat) async throws
    /// Send an audio chunk during streaming
    func sendAudioChunk(_ data: Data) async throws
    /// End the stream and get the final transcript
    func stopStreaming() async throws -> String
    /// Stream of partial results
    var transcriptionStream: AsyncStream<TranscriptionSegment> { get }
}

// MARK: - Rewrite

struct RewriteContext {
    let activeAppName: String
    let rewriteLevel: RewriteLevel
    let customDictionary: [DictionaryEntry]
    let suggestedTone: String
}

protocol RewriteProvider {
    var name: String { get }
    var providerType: RewriteProviderType { get }

    func rewrite(text: String, context: RewriteContext) async throws -> String
}

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case noAPIKey(String)
    case networkError(Error)
    case invalidResponse(String)
    case rateLimited
    case serverError(Int, String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey(let provider): "No API key configured for \(provider). Add it in Settings → Models Library."
        case .networkError(let error): "Network error: \(error.localizedDescription)"
        case .invalidResponse(let detail): "Invalid response from API: \(detail)"
        case .rateLimited: "Rate limited. Please wait a moment and try again."
        case .serverError(let code, let message): "Server error (\(code)): \(message)"
        }
    }
}
