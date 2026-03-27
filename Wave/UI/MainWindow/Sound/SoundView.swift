import SwiftUI

struct SoundView: View {
    @Bindable var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
                microphoneSection
                playbackSection
                soundEffectsSection
            }
            .padding(WaveTheme.spacingXL)
        }
        .onChange(of: appState.autoIncreaseVolume) { appState.saveToPreferences() }
        .onChange(of: appState.silenceRemoval) { appState.saveToPreferences() }
        .onChange(of: appState.playbackBehavior) { appState.saveToPreferences() }
        .onChange(of: appState.soundEffectsEnabled) { appState.saveToPreferences() }
        .onChange(of: appState.soundEffectsVolume) { appState.saveToPreferences() }
    }

    private var microphoneSection: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Microphone")
                .sectionHeader()

            VStack(spacing: 1) {
                SettingsToggleRow(
                    title: "Automatically increase microphone volume",
                    helpText: "Boosts input volume for better transcription accuracy",
                    isOn: $appState.autoIncreaseVolume
                )
                Divider().padding(.horizontal, WaveTheme.spacingMD)
                SettingsToggleRow(
                    title: "Silence removal",
                    helpText: "Remove silent segments from audio before transcription",
                    isOn: $appState.silenceRemoval
                )
            }
            .cardStyle()
        }
    }

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Playback")
                .sectionHeader()

            VStack {
                HStack {
                    Text("Playback when recording")
                        .font(.system(size: 13, weight: .medium))
                    HelpTooltipIcon(text: "Control how Wave handles media playback (Spotify, Apple Music, etc.) when recording starts")
                    Spacer()
                    Picker("", selection: $appState.playbackBehavior) {
                        ForEach(PlaybackBehavior.allCases, id: \.self) { behavior in
                            Text(behavior.rawValue).tag(behavior)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                }
                .padding(.vertical, WaveTheme.spacingSM)
            }
            .cardStyle()
        }
    }

    private var soundEffectsSection: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingMD) {
            Text("Sound Effects")
                .sectionHeader()

            VStack(spacing: WaveTheme.spacingSM) {
                SettingsToggleRow(
                    title: "Enable sound effects",
                    helpText: "Play Siri-style beep when recording starts and stops",
                    isOn: $appState.soundEffectsEnabled
                )

                if appState.soundEffectsEnabled {
                    Divider()

                    HStack(spacing: WaveTheme.spacingSM) {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(WaveTheme.textSecondary)
                        DottedSlider(value: $appState.soundEffectsVolume)
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(WaveTheme.textSecondary)
                    }
                    .padding(.vertical, WaveTheme.spacingMD)
                }
            }
            .cardStyle()
        }
    }
}
