import SwiftUI

struct VocabularyView: View {
    @State private var entries: [DictionaryEntry] = []
    @State private var selectedCategory: DictionaryEntry.Category? = nil
    @State private var newWord = ""
    @State private var newReplacement = ""
    @State private var newCategory: DictionaryEntry.Category = .general

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                WaveSectionHeader(
                    "Vocabulary",
                    subtitle: "Words Wave should always get right."
                )

                addWordForm
                categoryFilter
                entriesList
            }
            .padding(Wave.spacing.s32)
        }
        .onAppear {
            loadEntries()
        }
    }

    // MARK: - Add word form

    private var addWordForm: some View {
        WaveCard {
            VStack(alignment: .leading, spacing: Wave.spacing.s12) {
                Text("Add Word")
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)

                HStack(spacing: Wave.spacing.s8) {
                    TextField("New word or sentence", text: $newWord)
                        .textFieldStyle(.roundedBorder)

                    TextField("Replace with... (optional)", text: $newReplacement)
                        .textFieldStyle(.roundedBorder)

                    Picker("", selection: $newCategory) {
                        ForEach(DictionaryEntry.Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                    .frame(width: 100)

                    WaveButton("Add", kind: .primary) {
                        addEntry()
                    }
                    .disabled(newWord.isEmpty)
                }
            }
        }
    }

    // MARK: - Category filter chips

    private var categoryFilter: some View {
        HStack(spacing: Wave.spacing.s8) {
            WaveChip(title: "All", isSelected: selectedCategory == nil) {
                selectedCategory = nil
                loadEntries()
            }
            ForEach(DictionaryEntry.Category.allCases, id: \.self) { category in
                WaveChip(
                    title: category.rawValue.capitalized,
                    isSelected: selectedCategory == category
                ) {
                    selectedCategory = category
                    loadEntries()
                }
            }
        }
    }

    // MARK: - Entries list

    private var entriesList: some View {
        Group {
            if entries.isEmpty {
                WaveEmptyState(
                    icon: "book",
                    title: "No words yet",
                    subtitle: "Add words Wave should always transcribe correctly."
                )
                .frame(height: 200)
            } else {
                WaveCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            WaveListItem(
                                title: entry.word,
                                subtitle: entry.replacement
                            ) {
                                Button {
                                    deleteEntry(id: entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .waveFont(Wave.font.caption)
                                        .foregroundStyle(Wave.colors.destructive)
                                        .frame(width: 28, height: 28)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(PressScale())
                            }

                            if index < entries.count - 1 {
                                Divider()
                                    .foregroundStyle(Wave.colors.border)
                                    .padding(.horizontal, Wave.spacing.s12)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Data logic

    private func addEntry() {
        let entry = DictionaryEntry(
            word: newWord,
            replacement: newReplacement.isEmpty ? nil : newReplacement,
            category: newCategory
        )
        try? DatabaseManager.shared.addDictionaryEntry(entry)
        newWord = ""
        newReplacement = ""
        loadEntries()
    }

    private func deleteEntry(id: String) {
        try? DatabaseManager.shared.deleteDictionaryEntry(id: id)
        loadEntries()
    }

    private func loadEntries() {
        entries = (try? DatabaseManager.shared.fetchDictionaryEntries(category: selectedCategory)) ?? []
    }
}
