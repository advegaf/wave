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

    let totalSteps = 2

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: WaveTheme.spacingSM) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? WaveTheme.accent : WaveTheme.surfaceSecondary)
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, WaveTheme.spacingXXL)
            .padding(.top, WaveTheme.spacingLG)

            Spacer()

            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: modelAndFinishStep
                default: EmptyView()
                }
            }
            .padding(.horizontal, WaveTheme.spacingXXL)

            Spacer()

            // Navigation
            HStack {
                if currentStep == 1 && !modelDownloaded {
                    Button("Back") {
                        withAnimation(.easeOut(duration: 0.2)) { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(WaveTheme.textSecondary)
                }

                Spacer()

                if currentStep == 1 {
                    if modelDownloaded {
                        Button("Get Started") { saveAndFinish() }
                            .buttonStyle(.borderedProminent)
                    } else if !isDownloadingModel && modelError == nil {
                        Button("Download Model") { startModelDownload() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    Button("Continue") {
                        withAnimation(.easeOut(duration: 0.2)) { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(WaveTheme.spacingXL)
        }
        .frame(
            minWidth: WaveTheme.windowWidth,
            minHeight: WaveTheme.windowHeight
        )
        .background(WaveTheme.background)
    }

    // MARK: - Step 0: Welcome + Permissions

    private var welcomeStep: some View {
        VStack(spacing: WaveTheme.spacingXL) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(spacing: WaveTheme.spacingSM) {
                Text("Welcome to Wave")
                    .font(.system(size: 24, weight: .bold))

                Text("Turn your voice into polished text, anywhere on your Mac.")
                    .font(.system(size: 14))
                    .foregroundStyle(WaveTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }

            VStack(spacing: WaveTheme.spacingMD) {
                PermissionRow(
                    title: "Microphone",
                    description: "Required for voice recording",
                    isGranted: AudioSessionManager.shared.hasMicrophonePermission,
                    action: {
                        Task { await AudioSessionManager.shared.requestMicrophonePermission() }
                    }
                )

                PermissionRow(
                    title: "Accessibility",
                    description: "Required to paste text into other apps",
                    isGranted: AccessibilityManager.shared.isAccessibilityEnabled,
                    action: {
                        AccessibilityManager.shared.requestAccessibilityPermission()
                    }
                )
            }
        }
    }

    // MARK: - Step 1: Model Download + Finish

    private var modelAndFinishStep: some View {
        VStack(spacing: WaveTheme.spacingLG) {
            Image(systemName: modelDownloaded ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(modelDownloaded ? .green : WaveTheme.accent)

            Text(modelDownloaded ? "You're all set!" : "Download Voice Model")
                .font(.system(size: 24, weight: .bold))

            if modelDownloaded {
                Text("Press ⌘⇧Space anywhere to start recording.\nWave will transcribe, clean up, and paste your text.")
                    .font(.system(size: 13))
                    .foregroundStyle(WaveTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            } else {
                Text("Wave uses a local AI model (~150 MB) for fast, private speech recognition. It runs entirely on your Mac.")
                    .font(.system(size: 13))
                    .foregroundStyle(WaveTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 380)
            }

            if isDownloadingModel {
                VStack(spacing: WaveTheme.spacingMD) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(downloadStatus)
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textSecondary)
                }
                .padding(.top, WaveTheme.spacingSM)
            }

            if let error = modelError {
                VStack(spacing: WaveTheme.spacingSM) {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.destructive)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        modelError = nil
                        startModelDownload()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, WaveTheme.spacingSM)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(WaveTheme.textSecondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 20))
            } else {
                Button("Grant") { action() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .cardStyle()
    }
}
