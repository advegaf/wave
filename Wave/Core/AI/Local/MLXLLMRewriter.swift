import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Owns a single loaded MLX language model and produces text rewrites against it.
///
/// **Why this is not a `ChatSession`:** local 3B-class instruct models default
/// to chatbot behavior when you call them via the chat completion path. They
/// see a "user" message and feel obligated to *respond* to it instead of
/// transforming it. To get reliable text-cleanup behavior we instead build a
/// single completion-style prompt (system rules + few-shot examples + the
/// transcription + an `Output:` suffix) and let the model continue. We still
/// wrap the prompt with the model's native chat template so token IDs match
/// what it was trained on.
///
/// Lifecycle:
/// 1. `load(entry:progress:)` downloads + loads a model. Idempotent for the
///    same id.
/// 2. `rewrite(prompt:)` runs one inference and returns the generated text.
/// 3. `unload()` drops the container so MLX can free GPU/CPU memory.
actor MLXLLMRewriter {

    /// Currently loaded MLX LLM model id (Wave-side id from LocalLLMRegistry).
    private(set) var loadedModelId: String?

    private var container: ModelContainer?

    /// Sampling parameters tuned for short-form text rewriting:
    /// temperature 0 = fully deterministic, modest max-token cap to bound latency.
    private let defaultParameters = GenerateParameters(
        maxTokens: 512,
        temperature: 0.0,
        topP: 1.0
    )

    /// Substrings that, if seen at the start of a generated chunk, indicate
    /// the model has decided to start a new turn / preamble. Used as soft
    /// stop signals during streaming.
    private let stopMarkers: [String] = ["\nInput:", "Input:", "\n\nInput", "<|user|>", "<|im_start|>"]

    /// True if `load(entry:)` has succeeded since the last `unload()`.
    var isLoaded: Bool { container != nil }

    /// Download (if needed) and load a model from the registry. Idempotent —
    /// passing the same id while it's already loaded is a no-op. Switching
    /// ids unloads the previous model first.
    func load(
        entry: LocalLLMEntry,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        if loadedModelId == entry.id, container != nil {
            return
        }
        if container != nil {
            container = nil
            loadedModelId = nil
        }

        let configuration = entry.modelConfiguration()
        let loaded = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { progressInfo in
            progress?(progressInfo.fractionCompleted)
        }

        container = loaded
        loadedModelId = entry.id
    }

    /// Free the loaded model. Safe to call repeatedly.
    func unload() {
        container = nil
        loadedModelId = nil
    }

    /// Run a single completion against the loaded model.
    ///
    /// `prompt` is the **fully-built completion prompt** — typically produced
    /// by `PromptBuilder.buildCompletionPrompt(...)` and ending with
    /// `Output:` so the model knows where to start writing. We wrap this in
    /// a single user-role chat-template message and let the model complete
    /// the assistant turn. We do NOT use a system message — the rules are
    /// inlined in the user message because small models follow inline
    /// few-shot patterns more reliably than they follow split system+user.
    ///
    /// Throws `MLXLLMRewriterError.notLoaded` if no model is loaded.
    func rewrite(prompt: String) async throws -> String {
        guard let container else {
            throw MLXLLMRewriterError.notLoaded
        }

        let params = defaultParameters

        // ModelContainer.perform runs the closure on the actor's executor with
        // exclusive access to the (non-Sendable) ModelContext.
        let result = try await container.perform { (context: ModelContext) -> String in
            // Build LMInput by feeding the prompt as the only user message
            // through the model's chat template. This gives us the right
            // BOS/system/user/assistant tokens for whatever family is loaded
            // (Phi 3.5 / Llama 3.2 / Qwen 3 / etc).
            let messages: [[String: String]] = [
                ["role": "user", "content": prompt]
            ]
            let promptTokenIds = try context.tokenizer.applyChatTemplate(messages: messages)
            let input = LMInput(tokens: MLXArray(promptTokenIds))

            // Stream tokens. Accumulate, watch for soft stop markers.
            var output = ""
            let stream = try MLXLMCommon.generate(
                input: input,
                parameters: params,
                context: context
            )
            for await event in stream {
                guard case let .chunk(text) = event else {
                    if case .info = event { break }
                    continue
                }
                output += text
                if Self.containsAnyStopMarker(output, markers: Self.stopMarkersStatic) {
                    break
                }
            }
            return output
        }

        // Trim, strip any trailing stop-marker leftover, return.
        var cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        for marker in stopMarkers {
            if let range = cleaned.range(of: marker) {
                cleaned = String(cleaned[..<range.lowerBound])
                break
            }
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // The stop markers must be available inside the `perform { ... }` closure
    // which doesn't capture self. Mirror them as a static.
    private nonisolated static let stopMarkersStatic: [String] = [
        "\nInput:", "Input:", "\n\nInput", "<|user|>", "<|im_start|>"
    ]

    private nonisolated static func containsAnyStopMarker(_ s: String, markers: [String]) -> Bool {
        for m in markers where s.contains(m) {
            return true
        }
        return false
    }
}

enum MLXLLMRewriterError: LocalizedError {
    case notLoaded

    var errorDescription: String? {
        switch self {
        case .notLoaded:
            return "No local LLM is loaded. Download and select a model in Models Library."
        }
    }
}
