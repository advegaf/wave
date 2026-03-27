import SwiftUI
import KeyboardShortcuts

struct ConfigurationView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
                appearanceSection
                shortcutsSection
                applicationSection
            }
            .padding(WaveTheme.spacingXL)
        }
        .onChange(of: appState.overlayStyle) { appState.saveToPreferences() }
        .onChange(of: appState.overlayPositionY) { appState.saveToPreferences() }
    }

    // MARK: - Appearance (merged overlay style + position)

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Appearance")
                .sectionHeader()

            VStack(alignment: .leading, spacing: WaveTheme.spacingLG) {
                // Style picker
                VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
                    Text("Style")
                        .font(.system(size: 13, weight: .medium))

                    HStack(spacing: WaveTheme.spacingMD) {
                        OverlayStyleOption(
                            label: "Classic",
                            isSelected: appState.overlayStyle == .full,
                            action: { appState.overlayStyle = .full }
                        ) {
                            WaveformFullPreview()
                        }
                        OverlayStyleOption(
                            label: "Mini",
                            isSelected: appState.overlayStyle == .mini,
                            action: { appState.overlayStyle = .mini }
                        ) {
                            WaveformMiniPreview()
                        }
                    }
                }

                Divider()

                // Position
                VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
                    Text("Waveform height above dock")
                        .font(.system(size: 13, weight: .medium))

                    OverlayPositionPicker(positionY: $appState.overlayPositionY)

                    HStack {
                        Text("Distance: \(Int(appState.overlayPositionY))px above dock")
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .foregroundStyle(WaveTheme.textSecondary)
                        Spacer()
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Shortcuts

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Keyboard Shortcuts")
                .sectionHeader()

            VStack(spacing: 1) {
                ShortcutRow(
                    title: "Toggle Recording",
                    subtitle: "Starts and stops recordings"
                ) {
                    KeyboardShortcuts.Recorder(for: .toggleRecording)
                }

                Divider().padding(.horizontal, WaveTheme.spacingMD)

                ShortcutRow(
                    title: "Cancel Recording",
                    subtitle: "Discards the active recording"
                ) {
                    Text("esc")
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(WaveTheme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Divider().padding(.horizontal, WaveTheme.spacingMD)

                ShortcutRow(
                    title: "Change rewrite level",
                    subtitle: "Cycles through rewrite levels"
                ) {
                    KeyboardShortcuts.Recorder(for: .changeRewriteLevel)
                }

                Divider().padding(.horizontal, WaveTheme.spacingMD)

                ShortcutRow(
                    title: "Push to Talk",
                    subtitle: "Hold to record, release when done"
                ) {
                    KeyboardShortcuts.Recorder(for: .pushToTalk)
                }

                Divider().padding(.horizontal, WaveTheme.spacingMD)

                ShortcutRow(
                    title: "Mouse shortcut",
                    subtitle: "Tap to toggle, or hold and release when done"
                ) {
                    Text("Record shortcut")
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textTertiary)
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Application

    private var applicationSection: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Application")
                .sectionHeader()

            VStack(spacing: 1) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at login")
                            .font(.system(size: 13, weight: .medium))
                    }
                    HelpTooltipIcon(text: "Start Wave automatically when you log in")
                    Spacer()
                    Toggle("", isOn: .init(
                        get: { LaunchAtLoginManager.shared.isEnabled },
                        set: { LaunchAtLoginManager.shared.isEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                }
                .padding(.vertical, WaveTheme.spacingSM)
            }
            .cardStyle()
        }
    }
}

// MARK: - Overlay Position Picker

struct OverlayPositionPicker: View {
    @Binding var positionY: CGFloat

    private let positions: [(label: String, value: CGFloat)] = [
        ("Below dock", -30),
        ("On dock", -10),
        ("Dock level", 0),
        ("Just above", 10),
        ("Low", 30),
        ("Center", 120),
    ]

    var body: some View {
        VStack(spacing: WaveTheme.spacingSM) {
            // Visual screen representation
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(WaveTheme.surfaceSecondary)
                    .frame(height: 140)

                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(WaveTheme.border)
                        .frame(width: 120, height: 6)
                        .padding(.bottom, 8)
                }
                .frame(height: 140)

                VStack {
                    Spacer()
                    HStack(spacing: 1) {
                        let heights: [CGFloat] = [4, 7, 5, 9, 6, 10, 8, 5, 9, 7, 10, 6, 8, 4, 7]
                        ForEach(0..<15, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(WaveTheme.accent)
                                .frame(width: 2, height: heights[i])
                        }
                    }
                    .padding(.bottom, max(2, 14 + positionY / 3))
                }
                .frame(height: 140)
            }

            // Position preset buttons
            HStack(spacing: WaveTheme.spacingXS) {
                ForEach(positions, id: \.value) { pos in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            positionY = pos.value
                        }
                    } label: {
                        Text(pos.label)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(positionY == pos.value ? WaveTheme.accent.opacity(0.2) : WaveTheme.surfaceSecondary)
                            .foregroundStyle(positionY == pos.value ? WaveTheme.accent : WaveTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }

            Slider(value: $positionY, in: -50...300, step: 5)
                .tint(WaveTheme.accent)
        }
    }
}

// MARK: - Subviews

struct OverlayStyleOption<Preview: View>: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                preview()
                    .frame(width: 80, height: 50)
                    .background(WaveTheme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))
                Text(label)
                    .font(.system(size: 12))
            }
            .foregroundStyle(isSelected ? WaveTheme.accent : WaveTheme.textSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: WaveTheme.radiusInner)
                    .stroke(isSelected ? WaveTheme.accent : .clear, lineWidth: 2)
                    .padding(-4)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ShortcutRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(WaveTheme.textSecondary)
            }
            Spacer()
            content()
        }
        .padding(.vertical, WaveTheme.spacingSM)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let helpText: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium))
            HelpTooltipIcon(text: helpText)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
        }
        .padding(.vertical, WaveTheme.spacingSM)
    }
}
