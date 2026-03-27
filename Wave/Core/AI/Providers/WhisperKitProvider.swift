import Foundation
import WhisperKit

/// On-device Whisper transcription using WhisperKit + CoreML.
/// Runs entirely locally on Apple Silicon — no network calls.
final class WhisperKitProvider: TranscriptionProvider {
    let name = "WhisperKit (Local)"
    let providerType: TranscriptionProviderType = .whisper

    private var whisperKit: WhisperKit?
    private var isInitializing = false

    /// Initialize the model (downloads on first use, ~150MB for base)
    func initialize() async throws {
        guard whisperKit == nil, !isInitializing else { return }
        isInitializing = true

        print("[Wave] Initializing WhisperKit (local model)...")
        let startTime = CFAbsoluteTimeGetCurrent()

        whisperKit = try await WhisperKit(
            model: "base",
            computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine)
        )

        let elapsed = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
        print("[Wave] WhisperKit ready (\(elapsed)ms)")
        isInitializing = false
    }

    func transcribe(audioData: Data, format: AudioFormat) async throws -> String {
        // Ensure model is loaded
        if whisperKit == nil {
            try await initialize()
        }

        guard let kit = whisperKit else {
            throw AIServiceError.invalidResponse("WhisperKit failed to initialize")
        }

        // Convert WAV data to float samples
        let floatSamples = extractFloatSamples(from: audioData)

        guard !floatSamples.isEmpty else {
            throw AIServiceError.invalidResponse("No audio samples to transcribe")
        }

        // Transcribe locally
        let results = try await kit.transcribe(audioArray: floatSamples)

        let text = results.map { $0.text }.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return text
    }

    /// Extract Float samples from WAV data (skip 44-byte header, convert Int16 → Float)
    private func extractFloatSamples(from wavData: Data) -> [Float] {
        guard wavData.count > 44 else { return [] }

        let pcmData = wavData.dropFirst(44)
        let sampleCount = pcmData.count / 2 // Int16 = 2 bytes

        var floats = [Float](repeating: 0, count: sampleCount)
        pcmData.withUnsafeBytes { rawBuffer in
            let int16Buffer = rawBuffer.bindMemory(to: Int16.self)
            for i in 0..<sampleCount {
                floats[i] = Float(int16Buffer[i]) / Float(Int16.max)
            }
        }

        return floats
    }
}
