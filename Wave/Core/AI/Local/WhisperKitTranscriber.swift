import Foundation
import WhisperKit

/// On-device Whisper transcription via WhisperKit + CoreML. Pure-Swift, no network.
///
/// Refactored from `WhisperKitProvider`:
/// - Drops the (now-deleted) `TranscriptionProvider` protocol conformance
/// - Takes `[Float]` audio samples directly instead of WAV `Data` (SileroVAD
///   already gives us float frames; the WAV round-trip is wasted work)
///
/// Why a class and not an actor: `WhisperKit` itself is not `Sendable`, so
/// crossing an actor boundary with it triggers Swift 6 data-race errors. Owning
/// it from within `LocalAIEngine` (which IS an actor) gives us serialized access
/// without needing this type to be its own isolation domain.
final class WhisperKitTranscriber: @unchecked Sendable {

    /// Which Whisper model to load. Defaults to `base` to match existing behavior.
    var modelName: String = "base"

    private var whisperKit: WhisperKit?

    /// True after a successful `prepare()`.
    var isReady: Bool { whisperKit != nil }

    /// Download (if needed) and load the Whisper model into memory.
    /// Idempotent. Safe to call multiple times.
    func prepare() async throws {
        guard whisperKit == nil else { return }

        let started = CFAbsoluteTimeGetCurrent()
        whisperKit = try await WhisperKit(
            model: modelName,
            computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine)
        )
        let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - started) * 1000)
        print("[Wave] WhisperKit ready (\(modelName), \(elapsedMs) ms)")
    }

    /// Drop the loaded model and any cached files on disk so a fresh download
    /// can happen on next `prepare()`. Used by the "Re-download Model" button.
    func clearCacheAndReset() {
        whisperKit = nil

        let cacheDirectories = [
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("com.argmaxinc.whisperkit"),
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("huggingface"),
        ]

        for dir in cacheDirectories.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: dir.path) {
                try? FileManager.default.removeItem(at: dir)
                print("[Wave] Cleared WhisperKit cache: \(dir.path)")
            }
        }
    }

    /// Free the loaded model from memory without deleting on-disk caches.
    /// Used by `LocalAIEngine`'s idle-unload watcher.
    func unload() {
        whisperKit = nil
    }

    /// Transcribe a buffer of 16 kHz mono Float32 samples.
    /// - Throws `WhisperKitTranscriberError.empty` if `samples` is empty.
    /// - Throws `WhisperKitTranscriberError.notLoaded` if `prepare()` failed.
    func transcribe(samples: [Float]) async throws -> String {
        if whisperKit == nil {
            try await prepare()
        }
        guard let kit = whisperKit else {
            throw WhisperKitTranscriberError.notLoaded
        }
        guard !samples.isEmpty else {
            throw WhisperKitTranscriberError.empty
        }

        let results = try await kit.transcribe(audioArray: samples)
        let text = results.map { $0.text }.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }
}

enum WhisperKitTranscriberError: LocalizedError {
    case empty
    case notLoaded

    var errorDescription: String? {
        switch self {
        case .empty:
            return "No audio samples to transcribe"
        case .notLoaded:
            return "WhisperKit is not loaded yet"
        }
    }
}
