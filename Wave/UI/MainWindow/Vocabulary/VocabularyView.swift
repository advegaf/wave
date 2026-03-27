import SwiftUI

struct VocabularyView: View {
    @State private var entries: [DictionaryEntry] = []
    @State private var selectedCategory: DictionaryEntry.Category? = nil
    @State private var newWord = ""
    @State private var newReplacement = ""
    @State private var newCategory: DictionaryEntry.Category = .general
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
                VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
                    Text("Vocabulary")
                        .font(.system(size: 20, weight: .bold))
                    Text("Teach Wave to recognize people's names, company names, acronyms, slang, or words from other languages.")
                        .font(.system(size: 13))
                        .foregroundStyle(WaveTheme.textSecondary)
                }

                addWordForm
                categoryFilter
                entriesList
            }
            .padding(WaveTheme.spacingXL)
        }
        .onAppear {
            loadEntries()
        }
    }

    private var addWordForm: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
            Text("Input")
                .font(.system(size: 13, weight: .medium))

            HStack(spacing: WaveTheme.spacingSM) {
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

                Button("Add to vocabulary") {
                    addEntry()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newWord.isEmpty)
            }
        }
        .cardStyle()
    }

    private var categoryFilter: some View {
        HStack(spacing: WaveTheme.spacingSM) {
            FilterChip(label: "All", isSelected: selectedCategory == nil) {
                selectedCategory = nil
                loadEntries()
            }
            ForEach(DictionaryEntry.Category.allCases, id: \.self) { category in
                FilterChip(label: category.rawValue.capitalized, isSelected: selectedCategory == category) {
                    selectedCategory = category
                    loadEntries()
                }
            }
        }
    }

    private var entriesList: some View {
        Group {
            if entries.isEmpty {
                EmptyStateView(
                    icon: "book.fill",
                    title: "No words added yet",
                    subtitle: "Teach Wave custom words, names, or industry terms."
                )
                .frame(height: 200)
            } else {
                VStack(spacing: WaveTheme.spacingXS) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        VocabularyEntryCard(entry: entry) {
                            deleteEntry(id: entry.id)
                        }
                    }
                }
            }
        }
    }

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

struct VocabularyEntryCard: View {
    let entry: DictionaryEntry
    let onDelete: () -> Void

    var body: some View {
        HStack {
            if let replacement = entry.replacement {
                Text(entry.word)
                    .foregroundStyle(WaveTheme.textSecondary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundStyle(WaveTheme.textTertiary)
                Text(replacement)
                    .foregroundStyle(WaveTheme.textPrimary)
            } else {
                Text(entry.word)
                    .foregroundStyle(WaveTheme.textPrimary)
            }

            Spacer()

            Text(entry.category.rawValue.capitalized)
                .font(.system(size: 10))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(WaveTheme.surfaceSecondary)
                .clipShape(Capsule())
                .foregroundStyle(WaveTheme.textSecondary)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(WaveTheme.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(WaveTheme.spacingMD)
        .background(WaveTheme.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? WaveTheme.accent.opacity(0.2) : WaveTheme.surfacePrimary)
                .foregroundStyle(isSelected ? WaveTheme.accent : WaveTheme.textSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
