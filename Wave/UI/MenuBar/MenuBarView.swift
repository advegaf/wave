import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    var coordinator: RecordingCoordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status row
            HStack(spacing: Wave.spacing.s8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(Wave.colors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.top, Wave.spacing.s12)
            .padding(.bottom, Wave.spacing.s8)

            Divider().foregroundStyle(Wave.colors.border)

            // Start/stop recording
            Button(action: { coordinator.toggleRecording() }) {
                HStack(spacing: Wave.spacing.s8) {
                    Image(systemName: coordinator.state == .recording ? "stop.fill" : "record.circle")
                    Text(coordinator.state == .recording ? "Stop Recording" : "Start Recording")
                    Spacer()
                    Text("⌘⇧Space")
                        .waveFont(Wave.font.micro)
                        .foregroundStyle(Wave.colors.textTertiary)
                }
                .waveFont(Wave.font.nav)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }
            .buttonStyle(.plain)

            Divider().foregroundStyle(Wave.colors.border)

            // Rewrite level picker — no label, full width for 4 segments
            WaveSegmentedControl(selection: Binding(
                get: { appState.selectedRewriteLevel },
                set: { appState.selectedRewriteLevel = $0 }
            ))
            .padding(.horizontal, Wave.spacing.s16)
            .padding(.vertical, Wave.spacing.s10)

            // Last transcription preview
            if let last = coordinator.lastCleanedText, !last.isEmpty {
                Divider().foregroundStyle(Wave.colors.border)
                VStack(alignment: .leading, spacing: Wave.spacing.s6) {
                    HStack {
                        Text("Last transcription")
                            .waveFont(Wave.font.caption)
                            .foregroundStyle(Wave.colors.textSecondary)
                        Spacer()
                        Button(action: { copyLast(last) }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(Wave.colors.textSecondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }.buttonStyle(PressScale())
                    }
                    Text(preview(of: last))
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textPrimary)
                        .lineLimit(3)
                }
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }

            if let error = coordinator.lastError {
                Text(error)
                    .waveFont(Wave.font.captionLight)
                    .foregroundStyle(Wave.colors.destructive)
                    .lineLimit(2)
                    .padding(.horizontal, Wave.spacing.s16)
                    .padding(.bottom, Wave.spacing.s8)
            }

            Divider().foregroundStyle(Wave.colors.border)

            // Open / Quit
            Button(action: openMainWindow) {
                HStack {
                    Image(systemName: "rectangle.stack")
                    Text("Open Wave")
                    Spacer()
                }
                .waveFont(Wave.font.nav)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }.buttonStyle(.plain)

            Button(action: { NSApp.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit Wave")
                    Spacer()
                    Text("⌘Q")
                        .waveFont(Wave.font.micro)
                        .foregroundStyle(Wave.colors.textTertiary)
                }
                .waveFont(Wave.font.nav)
                .foregroundStyle(Wave.colors.textPrimary)
                .padding(.horizontal, Wave.spacing.s16)
                .padding(.vertical, Wave.spacing.s10)
            }.buttonStyle(.plain)
        }
        .frame(width: 380)
        .background(Wave.colors.surfacePrimary)
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch coordinator.state {
        case .idle:       return Wave.colors.success
        case .recording:  return Wave.colors.destructive
        case .processing, .activating, .pasting: return Wave.colors.warning
        case .cancelling: return Wave.colors.textTertiary
        }
    }

    private var statusText: String {
        switch coordinator.state {
        case .idle:       return "Ready"
        case .recording:  return "Recording"
        case .processing: return "Processing"
        case .activating: return "Activating"
        case .pasting:    return "Pasting"
        case .cancelling: return "Cancelling"
        }
    }

    private func preview(of text: String) -> String {
        text.count > 100 ? String(text.prefix(100)) + "..." : text
    }

    private func copyLast(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func openMainWindow() {
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
