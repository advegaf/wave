import Foundation

/// The screenshot lever.
///
/// `WAVE_DEMO=curated` puts the app into a fixed state for the capture run in
/// `Tools/Screenshots/make-docs-images.sh`. Two properties matter, both for the
/// same reason: a screenshot script must never photograph the person running it,
/// and re-running it must produce the same picture.
///
/// - The database is a throwaway file, deleted and reseeded on every demo
///   launch, so no real transcript or vocabulary can reach a published image.
/// - A demo run never writes preferences. `AppState` overrides what it needs in
///   memory and `saveToPreferences()` is not called, so the real defaults are
///   left exactly as the user set them.
///
/// The fixture is the *working* subset: entries that all look like normal use.
/// A catalogue of every empty and error state photographs as a bug report.
enum Demo {
    static let isActive = ProcessInfo.processInfo.environment["WAVE_DEMO"] == "curated"

    /// Which sidebar page the window opens to. Unset or unrecognised falls back
    /// to Home.
    static var page: SidebarItem {
        SidebarItem(rawValue: ProcessInfo.processInfo.environment["WAVE_DEMO_PAGE"] ?? "") ?? .home
    }

    /// Anchored to the actual launch, not a fixed instant. Home's stats bar
    /// asks the database for *this week*, so a hardcoded date silently ages out
    /// of the window and every figure photographs as a zero. The offsets below
    /// are what stay fixed, so the layout is reproducible even though the
    /// timestamps move with the calendar.
    static let now = Date()

    static func minutesAgo(_ minutes: Double) -> Date {
        now.addingTimeInterval(-minutes * 60)
    }

    static let vocabulary: [DictionaryEntry] = [
        DictionaryEntry(id: "demo-v1", word: "WhisperKit", replacement: nil,
                        category: .jargon, createdAt: minutesAgo(4_300), usageCount: 41),
        DictionaryEntry(id: "demo-v2", word: "SwiftUI", replacement: nil,
                        category: .jargon, createdAt: minutesAgo(4_120), usageCount: 33),
        DictionaryEntry(id: "demo-v3", word: "Xcode", replacement: nil,
                        category: .jargon, createdAt: minutesAgo(3_980), usageCount: 27),
        DictionaryEntry(id: "demo-v4", word: "advegaf", replacement: nil,
                        category: .names, createdAt: minutesAgo(3_600), usageCount: 18),
        DictionaryEntry(id: "demo-v5", word: "Apple Silicon", replacement: nil,
                        category: .jargon, createdAt: minutesAgo(2_800), usageCount: 12),
        DictionaryEntry(id: "demo-v6", word: "Houston", replacement: nil,
                        category: .places, createdAt: minutesAgo(1_500), usageCount: 9),
    ]

    static let snippets: [Snippet] = [
        Snippet(id: "demo-s1", triggerPhrase: "calendar",
                content: "Here is my scheduling link: cal.com/advegaf",
                createdAt: minutesAgo(5_000), updatedAt: minutesAgo(5_000)),
        Snippet(id: "demo-s2", triggerPhrase: "signoff",
                content: "Thanks, and let me know if anything above needs changing.",
                createdAt: minutesAgo(4_200), updatedAt: minutesAgo(4_200)),
        Snippet(id: "demo-s3", triggerPhrase: "address",
                content: "College Station, TX",
                createdAt: minutesAgo(2_100), updatedAt: minutesAgo(2_100)),
    ]

    /// Transcripts written to be unremarkable: the point of the picture is the
    /// interface, not the sentences in it.
    static let history: [HistoryEntry] = [
        HistoryEntry(id: "demo-h1",
                     rawTranscript: "um so can you take a look at the build when you get a sec, i think the signing step is what's failing",
                     cleanedText: "Could you take a look at the build when you get a chance? I think the signing step is what is failing.",
                     rewriteLevel: "moderate", sourceApp: "Slack",
                     voiceModel: "whisper-base", languageModel: "claude-haiku",
                     durationSeconds: 7.4, wordCount: 21, createdAt: minutesAgo(12)),
        HistoryEntry(id: "demo-h2",
                     rawTranscript: "meeting notes uh we agreed to ship the editor first and leave the import for next week",
                     cleanedText: "Meeting notes: we agreed to ship the editor first and leave the import until next week.",
                     rewriteLevel: "moderate", sourceApp: "Notes",
                     voiceModel: "whisper-base", languageModel: "claude-haiku",
                     durationSeconds: 6.1, wordCount: 16, createdAt: minutesAgo(54)),
        HistoryEntry(id: "demo-h3",
                     rawTranscript: "reply to the email and say the invoice is attached and the rest lands friday",
                     cleanedText: "The invoice is attached, and the rest will land on Friday.",
                     rewriteLevel: "light", sourceApp: "Mail",
                     voiceModel: "whisper-base", languageModel: "claude-haiku",
                     durationSeconds: 4.8, wordCount: 12, createdAt: minutesAgo(190)),
        HistoryEntry(id: "demo-h4",
                     rawTranscript: "todo rename the coordinator and pull the audio session setup out of it",
                     cleanedText: "Rename the coordinator and pull the audio session setup out of it.",
                     rewriteLevel: "light", sourceApp: "Xcode",
                     voiceModel: "whisper-base", languageModel: "claude-haiku",
                     durationSeconds: 5.2, wordCount: 13, createdAt: minutesAgo(420)),
        HistoryEntry(id: "demo-h5",
                     rawTranscript: "draft the intro paragraph explaining what the app does without the marketing voice",
                     cleanedText: "Draft the introduction explaining what the app does, without the marketing voice.",
                     rewriteLevel: "heavy", sourceApp: "Safari",
                     voiceModel: "whisper-base", languageModel: "claude-haiku",
                     durationSeconds: 5.9, wordCount: 13, createdAt: minutesAgo(1_180)),
    ]
}
