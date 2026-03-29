import SwiftUI

struct MenuBarView: View {
    var appState: AppState
    var coordinator: RecordingCoordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(coordinator.state.statusText)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, WaveTheme.spacingMD)
            .padding(.vertical, WaveTheme.spacingSM)

            Divider()

            // Record button
            Button {
                coordinator.toggleRecording()
            } label: {
                HStack {
                    Image(systemName: coordinator.state.isActive ? "stop.fill" : "record.circle")
                        .foregroundStyle(coordinator.state.isActive ? .red : WaveTheme.textPrimary)
                    Text(coordinator.state.isActive ? "Stop Recording" : "Start Recording")
                    Spacer()
                    Text("⌘⇧Space")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(WaveTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, WaveTheme.spacingMD)
            .padding(.vertical, WaveTheme.spacingSM)

            Divider()

            // Rewrite level
            HStack {
                Text("Rewrite:")
                    .font(.system(size: 11))
                    .foregroundStyle(WaveTheme.textSecondary)
                Picker("", selection: Binding(
                    get: { appState.selectedRewriteLevel },
                    set: { appState.selectedRewriteLevel = $0 }
                )) {
                    ForEach(RewriteLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.horizontal, WaveTheme.spacingMD)
            .padding(.vertical, WaveTheme.spacingSM)

            // Last transcription
            if let lastText = coordinator.lastCleanedText {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last transcription:")
                        .font(.system(size: 10))
                        .foregroundStyle(WaveTheme.textTertiary)
                    Text(lastText.prefix(100) + (lastText.count > 100 ? "..." : ""))
                        .font(.system(size: 11))
                        .foregroundStyle(WaveTheme.textSecondary)
                        .lineLimit(3)
                }
                .padding(.horizontal, WaveTheme.spacingMD)
                .padding(.vertical, WaveTheme.spacingSM)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(lastText, forType: .string)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Last Transcript")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, WaveTheme.spacingMD)
                .padding(.vertical, WaveTheme.spacingSM)
            }

            // Error
            if let error = coordinator.lastError {
                Divider()
                Text(error)
                    .font(.system(size: 10))
                    .foregroundStyle(WaveTheme.destructive)
                    .lineLimit(2)
                    .padding(.horizontal, WaveTheme.spacingMD)
                    .padding(.vertical, WaveTheme.spacingSM)
            }

            Divider()

            // Open app
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack {
                    Text("Open Wave")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, WaveTheme.spacingMD)
            .padding(.vertical, WaveTheme.spacingSM)

            Divider()

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit Wave")
                    Spacer()
                    Text("⌘Q")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(WaveTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, WaveTheme.spacingMD)
            .padding(.vertical, WaveTheme.spacingSM)
        }
        .frame(width: 300)
    }

    private var statusColor: Color {
        switch coordinator.state {
        case .idle: .green
        case .recording: .red
        case .processing, .activating, .pasting: .orange
        case .cancelling: .gray
        }
    }
}
