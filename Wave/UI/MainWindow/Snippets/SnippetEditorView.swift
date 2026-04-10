import SwiftUI

struct SnippetEditorView: View {
    @State var snippet: Snippet
    let isNew: Bool
    let onSave: (Snippet) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s16) {
            // Header
            WaveSectionHeader("Edit Snippet")
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.top, Wave.spacing.s16)

            // Trigger phrase
            VStack(alignment: .leading, spacing: Wave.spacing.s6) {
                Text("Trigger phrase")
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(Wave.colors.textSecondary)
                TextField("e.g., calendar, FAQ answer, signature", text: $snippet.triggerPhrase)
                    .waveFont(Wave.font.body)
                    .textFieldStyle(.plain)
                    .padding(Wave.spacing.s8)
                    .overlay(
                        RoundedRectangle(cornerRadius: Wave.radius.r8)
                            .stroke(Wave.colors.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, Wave.spacing.s16)

            // Content
            VStack(alignment: .leading, spacing: Wave.spacing.s6) {
                Text("Expanded content")
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(Wave.colors.textSecondary)
                TextEditor(text: $snippet.content)
                    .waveFont(Wave.font.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(Wave.spacing.s8)
                    .overlay(
                        RoundedRectangle(cornerRadius: Wave.radius.r8)
                            .stroke(Wave.colors.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, Wave.spacing.s16)

            Spacer()

            // Action buttons
            HStack {
                WaveButton("Delete", kind: .ghost) {
                    onDelete()
                }
                .foregroundStyle(Wave.colors.destructive)

                Spacer()

                WaveButton("Save", kind: .primary) {
                    snippet.updatedAt = Date()
                    onSave(snippet)
                }
                .disabled(snippet.triggerPhrase.isEmpty || snippet.content.isEmpty)
            }
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.bottom, Wave.spacing.s16)
        }
    }
}
