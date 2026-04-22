import SwiftUI
import WhisperKit

struct SetupWizardView: View {
    @Bindable var appState: AppState
    @State private var currentStep = 0
    // Model download state
    @State private var isDownloadingModel = false
    @State private var modelDownloaded = false
    @State private var modelError: String?
    @State private var downloadStatus = "Preparing..."
    // Permission state — tracked here so the view re-renders when the user
    // grants permission via the system dialog or System Settings.
    @State private var micGranted = AudioSessionManager.shared.hasMicrophonePermission
    @State private var accessibilityGranted = AccessibilityManager.shared.isAccessibilityEnabled

    let totalSteps = 2

    var body: some View {
        ZStack {
            Wave.colors.surfacePrimary
                .ignoresSafeArea()

            VStack(spacing: Wave.spacing.s24) {
                // Progress dots
                HStack(spacing: Wave.spacing.s8) {
                    ForEach(0..<totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? Wave.colors.accent : Wave.colors.border)
                            .frame(width: 32, height: 4)
                    }
                }
                .padding(.top, Wave.spacing.s32)

                // Active step — flat, no nested surface tone
                Group {
                    switch currentStep {
                    case 0: welcomeStep
                    case 1: modelAndFinishStep
                    default: EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Wave.spacing.s32)

                // Navigation buttons
                HStack {
                    if currentStep == 1 && !modelDownloaded {
                        WaveButton("Back", kind: .ghost) {
                            withAnimation(.easeOut(duration: 0.2)) { currentStep -= 1 }
                        }
                    }

                    Spacer()

                    if currentStep == 1 {
                        if modelDownloaded {
                            WaveButton("Get Started", kind: .primary) { saveAndFinish() }
                        } else if !isDownloadingModel && modelError == nil {
                            WaveButton("Download Model", kind: .primary) { startModelDownload() }
                        }
                    } else {
                        WaveButton("Continue", kind: .primary) {
                            withAnimation(.easeOut(duration: 0.2)) { currentStep += 1 }
                        }
                    }
                }
                .padding(.horizontal, Wave.spacing.s32)
                .padding(.bottom, Wave.spacing.s32)
            }
        }
        .frame(minWidth: 640, minHeight: 520)
        .onAppear { refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
    }

    private func refreshPermissions() {
        micGranted = AudioSessionManager.shared.hasMicrophonePermission
        accessibilityGranted = AccessibilityManager.shared.isAccessibilityEnabled
    }

    // MARK: - Step 0: Welcome + Permissions

    private var welcomeStep: some View {
        VStack(spacing: Wave.spacing.s24) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .imageOutline(radius: 18)
                .deepCardShadow()

            VStack(spacing: Wave.spacing.s8) {
                Text("Welcome to Wave")
                    .waveFont(Wave.font.displayHero)

                Text("Turn your voice into polished text, anywhere on your Mac.")
                    .waveFont(Wave.font.bodyLarge)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            VStack(spacing: Wave.spacing.s12) {
                PermissionRow(
                    title: "Microphone",
                    description: "Required for voice recording",
                    isGranted: micGranted,
                    action: {
                        Task {
                            let granted = await AudioSessionManager.shared.requestMicrophonePermission()
                            await MainActor.run { micGranted = granted }
                        }
                    }
                )

                PermissionRow(
                    title: "Accessibility",
                    description: "Required to paste text into other apps",
                    isGranted: accessibilityGranted,
                    action: {
                        AccessibilityManager.shared.requestAccessibilityPermission()
                    }
                )
            }
        }
    }

    // MARK: - Step 1: Model Download + Finish

    private var modelAndFinishStep: some View {
        VStack(spacing: Wave.spacing.s16) {
            Image(systemName: modelDownloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundStyle(modelDownloaded ? Wave.colors.success : Wave.colors.accent)

            Text(modelDownloaded ? "You're all set!" : "Download Voice Model")
                .waveFont(Wave.font.displayLarge)

            if modelDownloaded {
                Text("Press ⌘⇧Space anywhere to start recording.\nWave will transcribe, clean up, and paste your text.")
                    .waveFont(Wave.font.body)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            } else {
                Text("Wave uses a local AI model (~150 MB) for fast, private speech recognition. It runs entirely on your Mac.")
                    .waveFont(Wave.font.body)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            if isDownloadingModel {
                VStack(spacing: Wave.spacing.s12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(downloadStatus)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.textSecondary)
                }
                .padding(.top, Wave.spacing.s8)
            }

            if let error = modelError {
                VStack(spacing: Wave.spacing.s8) {
                    Text(error)
                        .waveFont(Wave.font.captionLight)
                        .foregroundStyle(Wave.colors.destructive)
                        .multilineTextAlignment(.center)
                    WaveButton("Retry", kind: .secondary) {
                        modelError = nil
                        startModelDownload()
                    }
                }
                .padding(.top, Wave.spacing.s8)
            }
        }
        .onAppear {
            if !modelDownloaded && !isDownloadingModel {
                startModelDownload()
            }
        }
    }

    // MARK: - Model Download

    private func startModelDownload() {
        isDownloadingModel = true
        modelError = nil
        downloadStatus = "Downloading WhisperKit base model..."

        Task {
            do {
                downloadStatus = "Downloading model (~150 MB)..."
                let _ = try await WhisperKit(
                    model: "base",
                    computeOptions: .init(audioEncoderCompute: .cpuAndNeuralEngine)
                )
                downloadStatus = "Model loaded successfully"
                isDownloadingModel = false
                modelDownloaded = true
            } catch {
                isDownloadingModel = false
                modelError = "Download failed: \(error.localizedDescription). Check your internet connection."
            }
        }
    }

    // MARK: - Save

    private func saveAndFinish() {
        appState.hasCompletedSetup = true
        appState.saveToPreferences()
    }
}

// MARK: - Subviews

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Wave.spacing.s2) {
                Text(title)
                    .waveFont(Wave.font.bodySemibold)
                Text(description)
                    .waveFont(Wave.font.captionLight)
                    .foregroundStyle(Wave.colors.textSecondary)
            }

            Spacer()

            // Both states stay in the layout and cross-fade so the row width
            // never jumps when the user grants permission.
            ZStack {
                WaveButton("Grant", kind: .primary) { action() }
                    .opacity(isGranted ? 0 : 1)
                    .allowsHitTesting(!isGranted)

                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Wave.colors.success)
                    .opacity(isGranted ? 1 : 0)
                    .scaleEffect(isGranted ? 1 : 0.6)
            }
            .animation(.easeInOut(duration: 0.18), value: isGranted)
        }
        .padding(Wave.spacing.s16)
        .background(Wave.colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Wave.radius.r8))
    }
}
