import SwiftUI

struct HistoryView: View {
    @State private var entries: [HistoryEntry] = []
    @State private var searchText = ""
    @State private var totalCount = 0
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(WaveTheme.textTertiary)
                TextField("Find...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit { search() }

                Spacer()

                Text("⌘F")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(WaveTheme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(WaveTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(WaveTheme.spacingMD)
            .background(WaveTheme.surfacePrimary)

            Divider()

            // History list
            if entries.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No recordings yet",
                    subtitle: "Press ⌘⇧Space to start your first recording."
                )
            }

            ScrollView {
                LazyVStack(spacing: WaveTheme.spacingSM) {
                    let grouped = Dictionary(grouping: entries) { entry in
                        Calendar.current.startOfDay(for: entry.createdAt)
                    }

                    ForEach(grouped.keys.sorted(by: >), id: \.self) { date in
                        Section {
                            ForEach(Array((grouped[date] ?? []).enumerated()), id: \.element.id) { index, entry in
                                HistoryEntryCard(entry: entry)
                                    .staggeredAppear(index: index, appeared: appeared)
                            }
                        } header: {
                            HStack {
                                Text(dateLabel(for: date))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(WaveTheme.textTertiary)
                                Spacer()
                            }
                            .padding(.top, WaveTheme.spacingSM)
                        }
                    }
                }
                .padding(WaveTheme.spacingLG)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Text("\(totalCount) Recordings")
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(WaveTheme.accent)
                Spacer()
            }
            .padding(WaveTheme.spacingSM)
        }
        .onAppear {
            loadHistory()
            triggerStaggerOnce(for: "history", appeared: &appeared)
        }
    }

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

struct HistoryEntryCard: View {
    let entry: HistoryEntry

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.cleanedText, forType: .string)
        } label: {
            HStack {
                Text(entry.cleanedText)
                    .font(.system(size: 13))
                    .foregroundStyle(WaveTheme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(WaveTheme.spacingMD)
            .background(WaveTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))
        }
        .buttonStyle(.pressableCard)
    }
}
