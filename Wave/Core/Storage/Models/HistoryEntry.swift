import Foundation
import GRDB

struct HistoryEntry: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var rawTranscript: String
    var cleanedText: String
    var rewriteLevel: String
    var sourceApp: String?
    var voiceModel: String
    var languageModel: String
    var durationSeconds: Double
    var wordCount: Int
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        rawTranscript: String,
        cleanedText: String,
        rewriteLevel: String,
        sourceApp: String? = nil,
        voiceModel: String,
        languageModel: String,
        durationSeconds: Double,
        wordCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.rawTranscript = rawTranscript
        self.cleanedText = cleanedText
        self.rewriteLevel = rewriteLevel
        self.sourceApp = sourceApp
        self.voiceModel = voiceModel
        self.languageModel = languageModel
        self.durationSeconds = durationSeconds
        self.wordCount = wordCount
        self.createdAt = createdAt
    }
}

extension HistoryEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "history_entries"

    enum Columns: String, ColumnExpression {
        case id, rawTranscript, cleanedText, rewriteLevel, sourceApp
        case voiceModel, languageModel, durationSeconds, wordCount, createdAt
    }
}
