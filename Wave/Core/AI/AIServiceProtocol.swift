import Foundation

/// Context passed to the rewriter for a single dictation. Used by both
/// `LocalAIEngine.rewrite(text:context:)` and `PromptBuilder` to construct
/// the model's system prompt with active-app and vocabulary information.
struct RewriteContext {
    let activeAppName: String
    let rewriteLevel: RewriteLevel
    let customDictionary: [DictionaryEntry]
    let suggestedTone: String
}
