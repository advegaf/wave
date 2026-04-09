import FluidAudio
import Foundation

/// Wave-side facade over FluidAudio's `VadManager`. Encapsulates Silero v6 VAD with
/// streaming hysteresis (onset/hangover) so the rest of Wave never imports FluidAudio
/// types directly.
///
/// The model is downloaded from HuggingFace on first `prepare()` call (via FluidAudio's
/// own download path) and cached afterwards. ~3 MB unified Silero v6.
///
/// Audio contract: 16 kHz mono Float32. Feed audio in `chunkSize`-sized slices (256 ms).
actor SileroVAD {

    /// 4096 samples = 256 ms @ 16 kHz. Aligned with FluidAudio's unified model.
    static let chunkSize: Int = VadManager.chunkSize

    /// Silero VAD operates at 16 kHz only.
    static let sampleRate: Int = VadManager.sampleRate

    private var manager: VadManager?
    private var streamState: VadStreamState?

    /// Tracks whether prepare() has been awaited successfully.
    var isReady: Bool { manager != nil }

    /// Lazily download + load the unified Silero v6 model. Idempotent.
    /// Throws if the model cannot be loaded (network/disk error on first run).
    func prepare(progress: (@Sendable (Double) -> Void)? = nil) async throws {
        guard manager == nil else { return }

        let config = VadConfig(
            defaultThreshold: 0.5,
            debugMode: false,
            computeUnits: .cpuAndNeuralEngine
        )

        let mgr = try await VadManager(config: config, progressHandler: { progressInfo in
            progress?(progressInfo.fractionCompleted)
        })
        manager = mgr
        streamState = await mgr.makeStreamState()
    }

    /// Reset the streaming state machine. Call before each new recording session
    /// so prior speech/silence history doesn't leak across sessions.
    func resetStream() async {
        guard let manager else { return }
        streamState = await manager.makeStreamState()
    }

    /// Process exactly one chunk of `chunkSize` samples (16 kHz mono Float32).
    /// Returns a `SpeechEvent` only on the chunks where a speech-start or speech-end
    /// boundary is crossed; nil otherwise.
    ///
    /// Caller is responsible for slicing the input audio stream into `chunkSize`
    /// chunks. Partial trailing chunks should be zero-padded to `chunkSize`.
    func process(chunk: [Float]) async throws -> SpeechEvent? {
        guard let manager, let state = streamState else {
            throw SileroVADError.notPrepared
        }

        let result = try await manager.processStreamingChunk(chunk, state: state)
        streamState = result.state

        guard let event = result.event else { return nil }
        switch event.kind {
        case .speechStart:
            return .speechStarted(sampleIndex: event.sampleIndex)
        case .speechEnd:
            return .speechEnded(sampleIndex: event.sampleIndex)
        }
    }

    enum SpeechEvent: Equatable, Sendable {
        case speechStarted(sampleIndex: Int)
        case speechEnded(sampleIndex: Int)
    }
}

enum SileroVADError: LocalizedError {
    case notPrepared

    var errorDescription: String? {
        switch self {
        case .notPrepared:
            return "SileroVAD must be prepared before processing audio"
        }
    }
}
