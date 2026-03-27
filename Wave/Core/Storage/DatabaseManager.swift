import Foundation
import GRDB

final class DatabaseManager: @unchecked Sendable {
    static let shared = DatabaseManager()

    private var dbPool: DatabasePool?

    func setup() throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let waveDir = appSupport.appendingPathComponent("Wave", isDirectory: true)
        try FileManager.default.createDirectory(at: waveDir, withIntermediateDirectories: true)

        let dbPath = waveDir.appendingPathComponent("wave.sqlite").path
        dbPool = try DatabasePool(path: dbPath)

        try migrator.migrate(dbPool!)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "dictionary_entries") { t in
                t.column("id", .text).primaryKey()
                t.column("word", .text).notNull()
                t.column("replacement", .text)
                t.column("category", .text).notNull().defaults(to: "general")
                t.column("createdAt", .datetime).notNull()
                t.column("usageCount", .integer).notNull().defaults(to: 0)
            }

            try db.create(table: "snippets") { t in
                t.column("id", .text).primaryKey()
                t.column("triggerPhrase", .text).notNull().unique()
                t.column("content", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.create(table: "history_entries") { t in
                t.column("id", .text).primaryKey()
                t.column("rawTranscript", .text).notNull()
                t.column("cleanedText", .text).notNull()
                t.column("rewriteLevel", .text).notNull()
                t.column("sourceApp", .text)
                t.column("voiceModel", .text).notNull()
                t.column("languageModel", .text).notNull()
                t.column("durationSeconds", .double).notNull()
                t.column("wordCount", .integer).notNull()
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(virtualTable: "history_fts", using: FTS5()) { t in
                t.synchronize(withTable: "history_entries")
                t.column("rawTranscript")
                t.column("cleanedText")
                t.column("sourceApp")
            }

            try db.create(table: "daily_stats") { t in
                t.column("date", .text).primaryKey()
                t.column("totalWords", .integer).notNull().defaults(to: 0)
                t.column("totalRecordings", .integer).notNull().defaults(to: 0)
                t.column("totalDurationSeconds", .double).notNull().defaults(to: 0)
                t.column("appsUsed", .text).notNull().defaults(to: "[]")
            }
        }

        migrator.registerMigration("v2") { db in
            try db.create(indexOn: "history_entries", columns: ["createdAt"])
        }

        return migrator
    }

    // MARK: - Dictionary CRUD

    func addDictionaryEntry(_ entry: DictionaryEntry) throws {
        try dbPool?.write { db in
            try entry.insert(db)
        }
    }

    func fetchDictionaryEntries(category: DictionaryEntry.Category? = nil) throws -> [DictionaryEntry] {
        try dbPool?.read { db in
            if let category {
                return try DictionaryEntry
                    .filter(DictionaryEntry.Columns.category == category.rawValue)
                    .order(DictionaryEntry.Columns.word)
                    .fetchAll(db)
            }
            return try DictionaryEntry.order(DictionaryEntry.Columns.word).fetchAll(db)
        } ?? []
    }

    func deleteDictionaryEntry(id: String) throws {
        try dbPool?.write { db in
            _ = try DictionaryEntry.deleteOne(db, id: id)
        }
    }

    // MARK: - Snippet CRUD

    func addSnippet(_ snippet: Snippet) throws {
        try dbPool?.write { db in
            try snippet.insert(db)
        }
    }

    func fetchSnippets() throws -> [Snippet] {
        try dbPool?.read { db in
            try Snippet.order(Snippet.Columns.triggerPhrase).fetchAll(db)
        } ?? []
    }

    func updateSnippet(_ snippet: Snippet) throws {
        try dbPool?.write { db in
            try snippet.update(db)
        }
    }

    func deleteSnippet(id: String) throws {
        try dbPool?.write { db in
            _ = try Snippet.deleteOne(db, id: id)
        }
    }

    // MARK: - History CRUD

    func addHistoryEntry(_ entry: HistoryEntry) throws {
        try dbPool?.write { db in
            try entry.insert(db)
        }
    }

    func fetchHistory(limit: Int = 50, offset: Int = 0) throws -> [HistoryEntry] {
        try dbPool?.read { db in
            try HistoryEntry
                .order(HistoryEntry.Columns.createdAt.desc)
                .limit(limit, offset: offset)
                .fetchAll(db)
        } ?? []
    }

    func searchHistory(query: String) throws -> [HistoryEntry] {
        try dbPool?.read { db in
            let sql = """
                SELECT history_entries.* FROM history_entries
                JOIN history_fts ON history_fts.rowid = history_entries.rowid
                WHERE history_fts MATCH ?
                ORDER BY history_entries.createdAt DESC
                """
            let pattern = FTS5Pattern(matchingAllPrefixesIn: query)
            return try HistoryEntry.fetchAll(db, sql: sql, arguments: [pattern])
        } ?? []
    }

    func fetchHistoryCount() throws -> Int {
        try dbPool?.read { db in
            try HistoryEntry.fetchCount(db)
        } ?? 0
    }

    func deleteHistoryEntry(id: String) throws {
        try dbPool?.write { db in
            _ = try HistoryEntry.deleteOne(db, id: id)
        }
    }

    // MARK: - Stats (single query for all weekly stats)

    struct WeeklyStats {
        var wordsThisWeek: Int = 0
        var averageWPM: Int = 0
        var uniqueApps: Int = 0
        var timeSavedMinutes: Int = 0
    }

    func fetchWeeklyStats() throws -> WeeklyStats {
        try dbPool?.read { db in
            let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let row = try Row.fetchOne(db, sql: """
                SELECT
                    COALESCE(SUM(wordCount), 0) as totalWords,
                    COALESCE(AVG(CASE WHEN durationSeconds > 0 THEN wordCount * 60.0 / durationSeconds END), 0) as avgWPM,
                    COUNT(DISTINCT sourceApp) as uniqueApps
                FROM history_entries
                WHERE createdAt >= ?
                """, arguments: [startOfWeek])
            let totalWords: Int = row?["totalWords"] ?? 0
            let avgWPM: Double = row?["avgWPM"] ?? 0
            let uniqueApps: Int = row?["uniqueApps"] ?? 0
            return WeeklyStats(
                wordsThisWeek: totalWords,
                averageWPM: Int(avgWPM),
                uniqueApps: uniqueApps,
                timeSavedMinutes: totalWords / 40
            )
        } ?? WeeklyStats()
    }
}
