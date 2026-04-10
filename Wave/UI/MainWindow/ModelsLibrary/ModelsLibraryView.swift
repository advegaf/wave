import SwiftUI

struct ModelsLibraryView: View {
    @Bindable var appState: AppState
    var coordinator: RecordingCoordinator
    @State private var selectedModel: AIModelConfig?
    @State private var isRedownloading = false

    private var voiceModels: [AIModelConfig] {
        AIModelConfig.defaultModels.filter { $0.modelType == .voice }
    }

    private var languageModels: [AIModelConfig] {
        AIModelConfig.defaultModels.filter { $0.modelType == .language }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Wave.spacing.s24) {
                WaveSectionHeader("Models Library")

                // Featured combo carousel
                featuredCarousel

                // Language Models section
                modelSection(
                    title: "Language Models",
                    description: "Used to clean up, rephrase, or translate the raw text. Trained on text data like sentences and paragraphs.",
                    models: languageModels
                )

                // Voice Models section
                modelSection(
                    title: "Voice Models",
                    description: "Used to recognize and transcribe spoken audio as accurately as possible. Trained on acoustic data like waveforms and phonetics.",
                    models: voiceModels
                )

                // WhisperKit local model status
                whisperKitStatusSection
            }
            .padding(Wave.spacing.s24)
        }
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Wave.spacing.s12) {
                heroCard(
                    title: "Best Accuracy",
                    subtitle: "Whisper + Claude",
                    description: "Highest quality transcription and rewriting",
                    accentColor: .purple
                )

                heroCard(
                    title: "Fastest",
                    subtitle: "Deepgram + GPT",
                    description: "Low latency real-time performance",
                    accentColor: .orange
                )

                heroCard(
                    title: "Budget",
                    subtitle: "Deepgram + GPT-mini",
                    description: "Cost-effective for everyday use",
                    accentColor: .green
                )
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }

    private func heroCard(
        title: String,
        subtitle: String,
        description: String,
        accentColor: Color
    ) -> some View {
        WaveCard(style: .hero, padding: Wave.spacing.s16) {
            VStack(alignment: .leading, spacing: Wave.spacing.s8) {
                Text(title)
                    .waveFont(Wave.font.caption)
                    .foregroundStyle(accentColor)

                Text(subtitle)
                    .waveFont(Wave.font.sectionHeading)
                    .foregroundStyle(Wave.colors.textPrimary)

                Text(description)
                    .waveFont(Wave.font.body)
                    .foregroundStyle(Wave.colors.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .frame(width: 208, height: 88, alignment: .leading)
        }
    }

    // MARK: - Model Section

    private func modelSection(title: String, description: String, models: [AIModelConfig]) -> some View {
        VStack(alignment: .leading, spacing: Wave.spacing.s8) {
            WaveSectionHeader(title, subtitle: description)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Wave.spacing.s12) {
                    ForEach(models, id: \.id) { model in
                        ModelCard(
                            model: model,
                            isActive: isModelActive(model),
                            onSelect: { activateModel(model) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - WhisperKit Status

    private var whisperKitStatusSection: some View {
        WaveCard(style: .standard) {
            VStack(alignment: .leading, spacing: Wave.spacing.s12) {
                Text("Local Voice Model")
                    .waveFont(Wave.font.cardTitle)
                    .foregroundStyle(Wave.colors.textPrimary)

                Text("WhisperKit runs speech recognition entirely on your Mac — no network calls required.")
                    .waveFont(Wave.font.body)
                    .foregroundStyle(Wave.colors.textSecondary)

                HStack(spacing: Wave.spacing.s12) {
                    // Status indicator
                    HStack(spacing: Wave.spacing.s8) {
                        Circle()
                            .fill(whisperKitStatusColor)
                            .frame(width: 8, height: 8)
                        Text(whisperKitStatusText)
                            .waveFont(Wave.font.body)
                            .foregroundStyle(Wave.colors.textSecondary)
                    }

                    Spacer()

                    if isRedownloading {
                        HStack(spacing: Wave.spacing.s8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Downloading...")
                                .waveFont(Wave.font.caption)
                                .foregroundStyle(Wave.colors.textSecondary)
                        }
                    } else {
                        WaveButton("Re-download", kind: .secondary) {
                            redownloadModel()
                        }
                    }
                }

                if let error = appState.whisperKitError {
                    Text(error)
                        .waveFont(Wave.font.caption)
                        .foregroundStyle(Wave.colors.destructive)
                }
            }
        }
    }

    private var whisperKitStatusColor: Color {
        if appState.isWhisperKitReady { return Wave.colors.success }
        if appState.whisperKitError != nil { return Wave.colors.destructive }
        return Wave.colors.warning
    }

    private var whisperKitStatusText: String {
        if appState.isWhisperKitReady { return "Ready" }
        if appState.whisperKitError != nil { return "Error" }
        return "Not initialized"
    }

    private func redownloadModel() {
        isRedownloading = true
        appState.whisperKitError = nil
        coordinator.clearWhisperKitCache()
        coordinator.preloadWhisperModel(appState: appState)
        Task {
            while !appState.isWhisperKitReady && appState.whisperKitError == nil {
                try? await Task.sleep(for: .milliseconds(500))
            }
            isRedownloading = false
        }
    }

    // MARK: - Model Selection

    private func isModelActive(_ model: AIModelConfig) -> Bool {
        if model.modelType == .voice { return true }
        if let id = model.localLLMId {
            return appState.selectedLocalLLMModelId == id
        }
        return false
    }

    private func activateModel(_ model: AIModelConfig) {
        guard let id = model.localLLMId else { return }
        appState.selectedLocalLLMModelId = id
        appState.saveToPreferences()
        coordinator.selectedLocalLLMModelId = id
    }
}
