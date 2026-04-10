import SwiftUI

struct HistoryView: View {
    @State private var entries: [HistoryEntry] = []
    @State private var searchText = ""
    @State private var totalCount = 0

    private var grouped: [Date: [HistoryEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.createdAt)
        }
    }

    private var sortedDates: [Date] {
        grouped.keys.sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {

                // MARK: Header
                WaveSectionHeader("History", subtitle: "\(totalCount) recordings")

                // MARK: Search field
                HStack(spacing: Wave.spacing.s8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Wave.colors.textTertiary)
                        .frame(width: 16)
                    TextField("Search recordings...", text: $searchText)
                        .textFieldStyle(.plain)
                        .waveFont(Wave.font.body)
                        .onSubmit { search() }
                        .onChange(of: searchText) { _ in
                            if searchText.isEmpty { loadHistory() }
                        }
                }
                .padding(.horizontal, Wave.spacing.s12)
                .padding(.vertical, Wave.spacing.s8)
                .background(Wave.colors.surfaceSecondary)
                .whisperBorder(radius: Wave.radius.r8)

                // MARK: Content
                if entries.isEmpty {
                    WaveEmptyState(
                        icon: "clock",
                        title: "No recordings yet",
                        subtitle: "Your dictation history will appear here."
                    )
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    VStack(alignment: .leading, spacing: Wave.spacing.s20) {
                        ForEach(sortedDates, id: \.self) { date in
                            VStack(alignment: .leading, spacing: Wave.spacing.s8) {

                                // Date group header
                                Text(dateLabel(for: date))
                                    .waveFont(Wave.font.bodySemibold)
                                    .foregroundStyle(Wave.colors.textSecondary)

                                // Entries card
                                WaveCard(padding: 0) {
                                    VStack(spacing: 0) {
                                        let dayEntries = grouped[date] ?? []
                                        ForEach(Array(dayEntries.enumerated()), id: \.element.id) { index, entry in
                                            HistoryRowView(entry: entry)

                                            if index < dayEntries.count - 1 {
                                                Divider()
                                                    .foregroundStyle(Wave.colors.border)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(Wave.spacing.s32)
        }
        .onAppear {
            loadHistory()
        }
    }

    // MARK: - Data

    private func loadHistory() {
        entries = (try? DatabaseManager.shared.fetchHistory()) ?? []
        totalCount = (try? DatabaseManager.shared.fetchHistoryCount()) ?? 0
    }

    private func search() {
        if searchText.isEmpty {
            loadHistory()
        } else {
            entries = (try? DatabaseManager.shared.searchHistory(query: searchText)) ?? []
        }
    }

    private func dateLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - History Row

private struct HistoryRowView: View {
    let entry: HistoryEntry
    @State private var isHovering = false

    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }

    var body: some View {
        HStack(spacing: Wave.spacing.s12) {
            // Leading: timestamp
            Text(timestamp)
                .waveFont(Wave.font.micro)
                .foregroundStyle(Wave.colors.textTertiary)
                .frame(width: 48, alignment: .leading)

            // Title + subtitle
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(entry.cleanedText)
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)
                    .lineLimit(2)
                if let sourceApp = entry.sourceApp, !sourceApp.isEmpty {
                    Text(sourceApp)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Accessory: copy icon on hover
            if isHovering {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(Wave.colors.textTertiary)
                    .frame(width: 16)
            }
        }
        .padding(.horizontal, Wave.spacing.s12)
        .padding(.vertical, Wave.spacing.s10)
        .background(isHovering ? Wave.colors.surfaceHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.cleanedText, forType: .string)
        }
    }
}
