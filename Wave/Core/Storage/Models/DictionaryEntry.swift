import Foundation
import GRDB

struct DictionaryEntry: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var word: String
    var replacement: String?
    var category: Category
    var createdAt: Date
    var usageCount: Int

    enum Category: String, CaseIterable, Codable {
        case names
        case jargon
        case places
        case general
    }

    init(id: String = UUID().uuidString, word: String, replacement: String? = nil, category: Category = .general, createdAt: Date = Date(), usageCount: Int = 0) {
        self.id = id
        self.word = word
        self.replacement = replacement
        self.category = category
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
}

extension DictionaryEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "dictionary_entries"

    enum Columns: String, ColumnExpression {
        case id, word, replacement, category, createdAt, usageCount
    }
}
