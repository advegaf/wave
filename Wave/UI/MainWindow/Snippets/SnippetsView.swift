import SwiftUI

struct SnippetsView: View {
    @State private var snippets: [Snippet] = []
    @State private var selectedSnippet: Snippet?
    @State private var isCreating = false
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // List panel
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Snippets")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button("Create snippet") {
                            isCreating = true
                            selectedSnippet = Snippet(triggerPhrase: "", content: "")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(WaveTheme.spacingLG)

                    Text("Define voice-triggered text expansions. Say the trigger phrase while recording and Wave will expand it to the full content.")
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textSecondary)
                        .padding(.horizontal, WaveTheme.spacingLG)
                        .padding(.bottom, WaveTheme.spacingMD)

                    if snippets.isEmpty {
                        EmptyStateView(
                            icon: "doc.text.fill",
                            title: "No snippets yet",
                            subtitle: "Create text expansions triggered by your voice.",
                            actionLabel: "Create your first snippet",
                            action: {
                                isCreating = true
                                selectedSnippet = Snippet(triggerPhrase: "", content: "")
                            }
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: WaveTheme.spacingXS) {
                                ForEach(Array(snippets.enumerated()), id: \.element.id) { index, snippet in
                                    Button {
                                        isCreating = false
                                        selectedSnippet = snippet
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(snippet.triggerPhrase)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundStyle(WaveTheme.textPrimary)
                                                Text(snippet.content.prefix(60) + (snippet.content.count > 60 ? "..." : ""))
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(WaveTheme.textSecondary)
                                                    .lineLimit(2)
                                            }
                                            Spacer()
                                            if selectedSnippet?.id == snippet.id {
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(WaveTheme.textTertiary)
                                            }
                                        }
                                        .padding(WaveTheme.spacingMD)
                                        .background(selectedSnippet?.id == snippet.id ? WaveTheme.surfaceHover : WaveTheme.surfacePrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))
                                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, WaveTheme.spacingLG)
                            .padding(.bottom, WaveTheme.spacingLG)
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.35)

                Divider()

                // Editor panel
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
                    EmptyStateView(
                        icon: "doc.text.fill",
                        title: "Select a snippet to edit",
                        subtitle: "Choose a snippet from the list or create a new one."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            loadSnippets()
        }
    }

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
