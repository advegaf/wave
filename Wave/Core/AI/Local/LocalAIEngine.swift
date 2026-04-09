import Foundation

/// Single facade over Wave's local AI inference surface. Owns the WhisperKit
/// transcriber, the MLX LLM rewriter, the model registry, and the idle-unload
/// watcher. The rest of Wave never imports MLX, WhisperKit, or FluidAudio
/// types — they only see this actor.
///
/// Threading: this is an `actor`, so all mutable state (loaded model id,
/// in-flight downloads, idle clock) is automatically serialized.
actor LocalAIEngine {

    // MARK: - Owned subsystems

    private let transcriber = WhisperKitTranscriber()
    private let rewriter = MLXLLMRewriter()
    private let idleWatcher = IdleWatcher()

    // MARK: - Observable state (read-only outside the actor)

    /// Currently loaded MLX LLM model id (Wave-side id from `LocalLLMRegistry`).
    private(set) var activeLLMId: String?

    /// True after WhisperKit has been prepared at least once in this session.
    private(set) var whisperReady: Bool = false

    /// In-flight LLM download task keyed by Wave-side model id, so callers
    /// awaiting the same id share a single download.
    private var inFlightDownloads: [String: Task<Void, Error>] = [:]

    // MARK: - Lifecycle

    /// Set the inactivity timeout for the LLM. Pass `nil` to never auto-unload,
    /// `0` to unload immediately after each rewrite, or seconds for delayed.
    func setIdleTimeout(_ seconds: TimeInterval?) async {
        await idleWatcher.setTimeout(seconds)
    }

    /// Start the idle watcher. Wires it to unload the LLM when fired.
    /// Call once during app startup. Subsequent calls replace the handler.
    func startIdleWatcher() async {
        await idleWatcher.start { [weak self] in
            await self?.unloadLLM()
        }
    }

    /// Preload both subsystems (WhisperKit + active LLM) in parallel so the
    /// first dictation has zero load latency. The active LLM is whatever was
    /// last selected by the user; if none is selected, this preloads only
    /// WhisperKit.
    func preloadActiveModels(activeLLMId: String?) async {
        async let whisperLoad: Void = preloadWhisper()
        async let llmLoad: Void = {
            if let activeLLMId, let entry = LocalLLMRegistry.find(id: activeLLMId) {
                _ = try? await loadLLM(entry: entry)
            }
        }()
        _ = await (whisperLoad, llmLoad)
    }

    private func preloadWhisper() async {
        do {
            try await transcriber.prepare()
            whisperReady = true
        } catch {
            print("[Wave] WhisperKit preload failed: \(error)")
            whisperReady = false
        }
    }

    /// Set the active LLM. Downloads the model if needed (progress reported
    /// via the callback) and loads it into memory. Idempotent for the same id.
    /// Cancels any in-flight download for a different id.
    func setActiveLLM(
        id: String,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        guard let entry = LocalLLMRegistry.find(id: id) else {
            throw LocalAIEngineError.unknownModel(id: id)
        }
        try await loadLLM(entry: entry, progress: progress)
    }

    /// Free the LLM from memory. Files on disk are kept; only the runtime
    /// allocation is dropped. Called by the idle watcher and on demand.
    func unloadLLM() async {
        await rewriter.unload()
        // Intentionally do not clear `activeLLMId` — the user's choice persists,
        // it just isn't resident in RAM right now.
    }

    /// Wipe WhisperKit's downloaded files and reset the in-memory handle.
    /// Used by the "Re-download Model" button.
    func clearWhisperKitCache() async {
        await transcriber.clearCacheAndReset()
        whisperReady = false
    }

    // MARK: - Public inference API

    /// Transcribe a buffer of 16 kHz mono Float32 samples. Touches the idle
    /// clock so the LLM doesn't unload mid-pipeline.
    func transcribe(samples: [Float]) async throws -> String {
        await idleWatcher.touch()
        return try await transcriber.transcribe(samples: samples)
    }

    /// Rewrite `rawText` using the active LLM and the prompt template for
    /// `context.rewriteLevel`. Builds a single completion-style prompt via
    /// `PromptBuilder` (system rules + few-shot examples + the transcription
    /// + an `Output:` suffix) and feeds it to `MLXLLMRewriter` as one user
    /// message. This avoids the chat-mode hallucinations that small instruct
    /// models produce when given a "user" message they want to respond to.
    /// Touches the idle clock. Throws if no LLM is loaded yet.
    func rewrite(text rawText: String, context: RewriteContext) async throws -> String {
        await idleWatcher.touch()

        // Lazy-load the active model on first rewrite if it isn't loaded yet.
        // (Idle-unload may have dropped it; user expects it to come back.)
        if await rewriter.isLoaded == false {
            guard let id = activeLLMId, let entry = LocalLLMRegistry.find(id: id) else {
                throw LocalAIEngineError.noActiveModel
            }
            try await loadLLM(entry: entry)
        }

        let prompt = PromptBuilder.buildCompletionPrompt(for: context, transcription: rawText)
        return try await rewriter.rewrite(prompt: prompt)
    }

    // MARK: - Private

    private func loadLLM(
        entry: LocalLLMEntry,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        // Coalesce concurrent loads of the same id.
        if let existing = inFlightDownloads[entry.id] {
            try await existing.value
            return
        }

        let task = Task { [rewriter] in
            try await rewriter.load(entry: entry, progress: progress)
        }
        inFlightDownloads[entry.id] = task
        defer { inFlightDownloads[entry.id] = nil }

        try await task.value
        activeLLMId = entry.id
    }
}

enum LocalAIEngineError: LocalizedError {
    case unknownModel(id: String)
    case noActiveModel

    var errorDescription: String? {
        switch self {
        case .unknownModel(let id):
            return "Unknown local LLM id: \(id)"
        case .noActiveModel:
            return "No local LLM is selected. Open Models Library to download and pick one."
        }
    }
}
