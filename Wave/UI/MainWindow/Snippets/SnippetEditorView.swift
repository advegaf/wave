import SwiftUI

struct SnippetEditorView: View {
    @State var snippet: Snippet
    let isNew: Bool
    let onSave: (Snippet) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingLG) {
            // Header
            HStack {
                Text(isNew ? "New Snippet" : "Edit Snippet")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                if !isNew {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(WaveTheme.destructive)
                }
            }

            // Trigger phrase
            VStack(alignment: .leading, spacing: WaveTheme.spacingXS) {
                Text("Trigger phrase")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WaveTheme.textSecondary)
                TextField("e.g., calendar, FAQ answer, signature", text: $snippet.triggerPhrase)
                    .textFieldStyle(.roundedBorder)
            }

            // Content
            VStack(alignment: .leading, spacing: WaveTheme.spacingXS) {
                Text("Expanded content")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WaveTheme.textSecondary)
                TextEditor(text: $snippet.content)
                    .font(.system(size: 13))
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .padding(WaveTheme.spacingSM)
                    .background(WaveTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusSM))
            }

            Spacer()

            // Save button
            HStack {
                Spacer()
                Button("Save") {
                    snippet.updatedAt = Date()
                    onSave(snippet)
                }
                .buttonStyle(.borderedProminent)
                .disabled(snippet.triggerPhrase.isEmpty || snippet.content.isEmpty)
            }
        }
        .padding(WaveTheme.spacingXL)
    }
}
