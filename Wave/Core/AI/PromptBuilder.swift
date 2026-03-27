import Foundation

struct PromptBuilder {
    nonisolated(unsafe) private static var templateCache: [String: String] = [:]

    static func buildSystemPrompt(for context: RewriteContext) -> String {
        let templateName = context.rewriteLevel.promptFileName

        let template: String
        if let cached = templateCache[templateName] {
            template = cached
        } else if let url = Bundle.main.url(forResource: templateName, withExtension: "txt", subdirectory: "DefaultPrompts"),
                  let loaded = try? String(contentsOf: url, encoding: .utf8) {
            templateCache[templateName] = loaded
            template = loaded
        } else {
            return fallbackPrompt(for: context)
        }

        var result = template
        result = result.replacingOccurrences(of: "{{APP_NAME}}", with: context.activeAppName)
        result = result.replacingOccurrences(of: "{{DICTIONARY_CONTEXT}}", with: buildDictionaryContext(from: context.customDictionary))
        return result
    }

    private static func buildDictionaryContext(from entries: [DictionaryEntry]) -> String {
        guard !entries.isEmpty else {
            return ""
        }

        var lines = ["The following are correct spellings and terms the user has defined:"]

        for entry in entries {
            if let replacement = entry.replacement {
                lines.append("- \"\(entry.word)\" should be written as \"\(replacement)\"")
            } else {
                lines.append("- \"\(entry.word)\" (correct spelling, do not change)")
            }
        }

        return lines.joined(separator: "\n")
    }

    private static func fallbackPrompt(for context: RewriteContext) -> String {
        """
        You are a dictation cleanup assistant. The user dictated the following text while using \(context.activeAppName).

        Clean it at a \(context.rewriteLevel.rawValue.lowercased()) level. Remove filler words, fix grammar, \
        and make it read naturally. The tone should be \(context.suggestedTone).

        \(buildDictionaryContext(from: context.customDictionary))

        Return ONLY the cleaned text. No explanations, no quotes, no markdown.
        """
    }
}
