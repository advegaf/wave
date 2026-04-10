import SwiftUI

struct SoundView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                microphoneSection
                playbackSection
                soundEffectsSection
            }
            .padding(Wave.spacing.s24)
        }
        .onChange(of: appState.autoIncreaseVolume) { appState.saveToPreferences() }
        .onChange(of: appState.silenceRemoval) { appState.saveToPreferences() }
        .onChange(of: appState.playbackBehavior) { appState.saveToPreferences() }
        .onChange(of: appState.soundEffectsEnabled) { appState.saveToPreferences() }
        .onChange(of: appState.soundEffectsVolume) { appState.saveToPreferences() }
    }

    private var microphoneSection: some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s12) {
            WaveSectionHeader("Microphone")

            WaveCard {
                VStack(spacing: 0) {
                    WaveSettingRow("Automatically increase microphone volume") {
                        HStack(spacing: Wave.spacing.s8) {
                            WaveHelpTooltip(helpText: "Boosts input volume for better transcription accuracy")
                            Toggle("", isOn: $appState.autoIncreaseVolume).toggleStyle(.switch)
                        }
                    }
                    Divider().padding(.horizontal, Wave.spacing.s12)
                    WaveSettingRow("Silence removal") {
                        HStack(spacing: Wave.spacing.s8) {
                            WaveHelpTooltip(helpText: "Remove silent segments from audio before transcription")
                            Toggle("", isOn: $appState.silenceRemoval).toggleStyle(.switch)
                        }
                    }
                }
            }
        }
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s12) {
            WaveSectionHeader("Playback & Sound Effects")

            WaveCard {
                VStack(spacing: 0) {
                    WaveSettingRow(
                        "Playback when recording",
                        subtitle: "Control how Wave handles media playback when recording starts"
                    ) {
                        EmptyView()
                    }

                    Divider().padding(.horizontal, Wave.spacing.s12)

                    ForEach(PlaybackBehavior.allCases, id: \.self) { behavior in
                        playbackRadioRow(for: behavior)
                        if behavior != PlaybackBehavior.allCases.last {
                            Divider().padding(.horizontal, Wave.spacing.s12)
                        }
                    }
                }
            }
        }
    }

    private func playbackRadioRow(for behavior: PlaybackBehavior) -> some View {
        Button {
            appState.playbackBehavior = behavior
        } label: {
            HStack(spacing: Wave.spacing.s12) {
                Image(systemName: appState.playbackBehavior == behavior
                    ? "circle.fill"
                    : "circle")
                    .foregroundStyle(appState.playbackBehavior == behavior
                        ? Wave.colors.accent
                        : Wave.colors.textTertiary)
                    .imageScale(.small)

                Text(behavior.rawValue)
                    .waveFont(Wave.font.bodyMedium)
                    .foregroundStyle(Wave.colors.textPrimary)

                Spacer()
            }
            .padding(.vertical, Wave.spacing.s8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Bridge Float AppState property to the Double Binding WaveDottedSlider expects.
    private var soundEffectsVolumeDouble: Binding<Double> {
        Binding(
            get: { Double(appState.soundEffectsVolume) },
            set: { appState.soundEffectsVolume = Float($0) }
        )
    }

    private var soundEffectsSection: some View {
        WaveCard {
            VStack(spacing: 0) {
                WaveSettingRow("Enable sound effects") {
                    HStack(spacing: Wave.spacing.s8) {
                        WaveHelpTooltip(helpText: "Play Siri-style beep when recording starts and stops")
                        Toggle("", isOn: $appState.soundEffectsEnabled).toggleStyle(.switch)
                    }
                }

                if appState.soundEffectsEnabled {
                    Divider().padding(.horizontal, Wave.spacing.s12)

                    HStack(spacing: Wave.spacing.s8) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(Wave.colors.textSecondary)
                            .imageScale(.small)
                        WaveDottedSlider(
                            value: soundEffectsVolumeDouble,
                            range: 0...1,
                            step: 0.05
                        )
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(Wave.colors.textSecondary)
                            .imageScale(.small)
                    }
                    .padding(.vertical, Wave.spacing.s12)
                }
            }
        }
    }
}
