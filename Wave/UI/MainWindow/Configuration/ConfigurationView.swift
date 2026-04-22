import SwiftUI
import KeyboardShortcuts

struct ConfigurationView: View {
    @Bindable var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previewController = OverlayWindowController()
    @State private var previewLevelMonitor = AudioLevelMonitor()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                appearanceSection
                animationSection
                shortcutsSection
                applicationSection
            }
            .padding(Wave.spacing.s24)
        }
        .onChange(of: appState.overlayStyle) { appState.saveToPreferences() }
        .onChange(of: appState.overlayPositionY) { appState.saveToPreferences() }
        .onChange(of: appState.overlayAnimationStyle) { appState.saveToPreferences() }
        .onChange(of: appState.overlayAnimationSpeed) { appState.saveToPreferences() }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        WaveCard {
            VStack(alignment: .leading, spacing: Wave.spacing.s16) {
                WaveSectionHeader("Appearance")

                Divider()

                // Style picker
                VStack(alignment: .leading, spacing: Wave.spacing.s8) {
                    Text("Style")
                        .waveFont(Wave.font.bodyMedium)
                        .foregroundStyle(Wave.colors.textPrimary)

                    HStack(spacing: Wave.spacing.s12) {
                        overlayStyleCard(
                            label: "Classic",
                            style: .full,
                            preview: { WaveformFullPreview() }
                        )
                        overlayStyleCard(
                            label: "Mini",
                            style: .mini,
                            preview: { WaveformMiniPreview() }
                        )
                        Spacer()
                    }
                }

                Divider()

                // Position
                WaveSettingRow("Position", subtitle: "Distance above dock") {
                    EmptyView()
                }

                overlayPositionContent
            }
        }
    }

    @ViewBuilder
    private func overlayStyleCard<Preview: View>(
        label: String,
        style: OverlayStyle,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        let isSelected = appState.overlayStyle == style
        Button(action: { appState.overlayStyle = style }) {
            VStack(spacing: Wave.spacing.s8) {
                preview()
                    .frame(width: 80, height: 50)
                    .background(Wave.colors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r4))
                Text(label)
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(isSelected ? Wave.colors.accent : Wave.colors.textSecondary)
            }
            .padding(Wave.spacing.s8)
            .background(Wave.colors.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r12))
            .overlay(
                RoundedRectangle(cornerRadius: Wave.radius.r12)
                    .stroke(isSelected ? Wave.colors.accent : Wave.colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PressScale())
    }

    private var overlayPositionContent: some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s12) {
            // Visual screen representation
            ZStack {
                RoundedRectangle(cornerRadius: Wave.radius.r8)
                    .fill(Wave.colors.surfaceSecondary)
                    .frame(height: 140)

                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: Wave.radius.r4)
                        .fill(Wave.colors.border)
                        .frame(width: 120, height: 6)
                        .padding(.bottom, Wave.spacing.s8)
                }
                .frame(height: 140)

                VStack {
                    Spacer()
                    HStack(spacing: 1) {
                        let heights: [CGFloat] = [4, 7, 5, 9, 6, 10, 8, 5, 9, 7, 10, 6, 8, 4, 7]
                        ForEach(0..<15, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Wave.colors.accent)
                                .frame(width: 2, height: heights[i])
                        }
                    }
                    .padding(.bottom, max(2, 14 + appState.overlayPositionY / 3))
                }
                .frame(height: 140)
            }

            // Preset buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Wave.spacing.s4) {
                    ForEach(overlayPositions, id: \.value) { pos in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                appState.overlayPositionY = pos.value
                            }
                        } label: {
                            Text(pos.label)
                                .waveFont(Wave.font.micro)
                                .padding(.horizontal, Wave.spacing.s6)
                                .padding(.vertical, Wave.spacing.s4)
                                .background(appState.overlayPositionY == pos.value ? Wave.colors.accent.opacity(0.15) : Wave.colors.surfaceSecondary)
                                .foregroundStyle(appState.overlayPositionY == pos.value ? Wave.colors.accent : Wave.colors.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r4))
                        }
                        .buttonStyle(PressScale())
                    }
                }
            }

            // Dotted slider — WaveDottedSlider uses Double, overlayPositionY is CGFloat
            WaveDottedSlider(
                value: Binding(
                    get: { Double(appState.overlayPositionY) },
                    set: { appState.overlayPositionY = CGFloat($0) }
                ),
                range: -50...300,
                step: 5
            )

            Text("Distance: \(Int(appState.overlayPositionY))px above dock")
                .waveFont(Wave.font.captionLight)
                .foregroundStyle(Wave.colors.textSecondary)
                .monospacedDigit()
        }
    }

    private let overlayPositions: [(label: String, value: CGFloat)] = [
        ("Below dock", -30),
        ("On dock", -10),
        ("Dock level", 0),
        ("Just above", 10),
        ("Low", 30),
        ("Center", 120),
    ]

    // MARK: - Animation

    private var animationSection: some View {
        WaveCard {
            VStack(alignment: .leading, spacing: Wave.spacing.s16) {
                WaveSectionHeader("Animation")

                Divider()

                VStack(alignment: .leading, spacing: Wave.spacing.s8) {
                    Text("Style")
                        .waveFont(Wave.font.bodyMedium)
                        .foregroundStyle(Wave.colors.textPrimary)

                    WaveSegmentedControl(selection: $appState.overlayAnimationStyle)
                }
                .disabled(reduceMotion)
                .opacity(reduceMotion ? 0.4 : 1)

                Divider()

                VStack(alignment: .leading, spacing: Wave.spacing.s8) {
                    HStack {
                        Text("Speed")
                            .waveFont(Wave.font.bodyMedium)
                            .foregroundStyle(Wave.colors.textPrimary)
                        Spacer()
                        Text(speedLabel)
                            .waveFont(Wave.font.captionLight)
                            .foregroundStyle(Wave.colors.textSecondary)
                            .monospacedDigit()
                    }

                    HStack(spacing: Wave.spacing.s12) {
                        WaveDottedSlider(
                            value: $appState.overlayAnimationSpeed,
                            range: 0.25...2.0,
                            step: 0.05
                        )
                        WaveButton("Try it", kind: .secondary, action: playPreview)
                            .disabled(reduceMotion)
                    }

                    HStack {
                        Text("0.25×")
                        Spacer()
                        Text("1×")
                        Spacer()
                        Text("2×")
                    }
                    .waveFont(Wave.font.micro)
                    .foregroundStyle(Wave.colors.textTertiary)
                }
                .disabled(reduceMotion)
                .opacity(reduceMotion ? 0.4 : 1)

                if reduceMotion {
                    Text("Disabled while macOS Reduce Motion is on. The overlay will fade in instantly.")
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
            }
        }
    }

    private var speedLabel: String {
        String(format: "%.2f×", appState.overlayAnimationSpeed)
    }

    private func playPreview() {
        guard !reduceMotion else { return }
        previewController.overlayStyle = appState.overlayStyle
        previewController.positionY = appState.overlayPositionY
        previewController.animationStyle = appState.overlayAnimationStyle
        previewController.animationSpeed = appState.overlayAnimationSpeed
        previewController.show(levelMonitor: previewLevelMonitor)

        let showDuration = 0.4 * appState.overlayAnimationSpeed
        DispatchQueue.main.asyncAfter(deadline: .now() + showDuration + 0.6) { [previewController] in
            previewController.hide()
        }
    }

    // MARK: - Keyboard Shortcuts

    private var shortcutsSection: some View {
        WaveCard {
            VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                WaveSectionHeader("Keyboard Shortcuts")

                Divider()

                WaveSettingRow("Toggle Recording", subtitle: "Starts and stops recordings") {
                    KeyboardShortcuts.Recorder(for: .toggleRecording)
                }

                Divider()

                WaveSettingRow("Cancel Recording", subtitle: "Discards the active recording") {
                    Text("esc")
                        .waveFont(Wave.font.captionLight)
                        .padding(.horizontal, Wave.spacing.s8)
                        .padding(.vertical, Wave.spacing.s4)
                        .background(Wave.colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r4))
                        .foregroundStyle(Wave.colors.textPrimary)
                }

                Divider()

                WaveSettingRow("Change rewrite level", subtitle: "Cycles through rewrite levels") {
                    KeyboardShortcuts.Recorder(for: .changeRewriteLevel)
                }

                Divider()

                WaveSettingRow("Push to Talk", subtitle: "Hold to record, release when done") {
                    KeyboardShortcuts.Recorder(for: .pushToTalk)
                }

                Divider()

                WaveSettingRow("Mouse shortcut", subtitle: "Tap to toggle, or hold and release when done") {
                    Text("Record shortcut")
                        .waveFont(Wave.font.caption)
                        .foregroundStyle(Wave.colors.textTertiary)
                }
            }
        }
    }

    // MARK: - Application Settings

    private var applicationSection: some View {
        WaveCard {
            VStack(alignment: .leading, spacing: Wave.spacing.s4) {
                WaveSectionHeader("Application Settings")

                Divider()

                WaveSettingRow("Launch at Login", subtitle: "Start Wave when you log in") {
                    HStack(spacing: Wave.spacing.s8) {
                        WaveHelpTooltip(helpText: "Start Wave automatically when you log in")
                        Toggle("", isOn: .init(
                            get: { LaunchAtLoginManager.shared.isEnabled },
                            set: { LaunchAtLoginManager.shared.isEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                    }
                }
            }
        }
    }
}
