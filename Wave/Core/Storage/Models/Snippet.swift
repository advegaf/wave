import Foundation
import GRDB

struct Snippet: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var triggerPhrase: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, triggerPhrase: String, content: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.triggerPhrase = triggerPhrase
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Snippet: FetchableRecord, PersistableRecord {
    static let databaseTableName = "snippets"

    enum Columns: String, ColumnExpression {
        case id, triggerPhrase, content, createdAt, updatedAt
    }
}
