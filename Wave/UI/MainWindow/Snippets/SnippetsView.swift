import SwiftUI

struct SnippetsView: View {
    @State private var snippets: [Snippet] = []
    @State private var selectedSnippet: Snippet?
    @State private var isCreating = false

    var body: some View {
        HStack(spacing: Wave.spacing.s16) {
            // Left pane (~40%)
            WaveCard(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    WaveSectionHeader(
                        "Snippets",
                        trailing: AnyView(
                            WaveButton("Add", icon: "plus", kind: .ghost) {
                                isCreating = true
                                selectedSnippet = Snippet(triggerPhrase: "", content: "")
                            }
                        )
                    )
                    .padding(.horizontal, Wave.spacing.s16)
                    .padding(.top, Wave.spacing.s16)
                    .padding(.bottom, Wave.spacing.s12)

                    if snippets.isEmpty {
                        WaveEmptyState(
                            icon: "doc.text",
                            title: "No snippets",
                            subtitle: "Create trigger phrases that expand into longer text."
                        )
                        .padding(Wave.spacing.s16)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(snippets, id: \.id) { snippet in
                                    let isSelected = selectedSnippet?.id == snippet.id
                                    let preview: String = {
                                        let c = snippet.content
                                        let firstLine = c.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? c
                                        return firstLine.count > 60 ? String(firstLine.prefix(60)) + "..." : firstLine
                                    }()

                                    WaveListItem(
                                        title: snippet.triggerPhrase,
                                        subtitle: preview,
                                        onTap: {
                                            isCreating = false
                                            selectedSnippet = snippet
                                        }
                                    )
                                    .background(isSelected ? Wave.colors.accent.opacity(0.08) : Color.clear)

                                    if snippet.id != snippets.last?.id {
                                        Divider()
                                            .foregroundStyle(Wave.colors.border)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .frame(width: nil)
            .layoutPriority(0.4)

            // Right pane (~60%)
            WaveCard(padding: 0) {
                if let snippet = selectedSnippet {
                    SnippetEditorView(
                        snippet: snippet,
                        isNew: isCreating,
                        onSave: { updated in
                            saveSnippet(updated)
                            isCreating = false
                        },
                        onDelete: {
                            deleteSnippet(id: snippet.id)
                            selectedSnippet = nil
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    WaveEmptyState(
                        icon: "pencil",
                        title: "Select a snippet"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .layoutPriority(0.6)
        }
        .padding(Wave.spacing.s16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            loadSnippets()
        }
    }

    // MARK: - Data

    private func loadSnippets() {
        snippets = (try? DatabaseManager.shared.fetchSnippets()) ?? []
    }

    private func saveSnippet(_ snippet: Snippet) {
        if isCreating {
            try? DatabaseManager.shared.addSnippet(snippet)
        } else {
            try? DatabaseManager.shared.updateSnippet(snippet)
        }
        loadSnippets()
    }

    private func deleteSnippet(id: String) {
        try? DatabaseManager.shared.deleteSnippet(id: id)
        loadSnippets()
    }
}
