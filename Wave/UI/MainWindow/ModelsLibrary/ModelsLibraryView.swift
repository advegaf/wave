import SwiftUI

struct ModelsLibraryView: View {
    @Bindable var appState: AppState
    @State private var selectedModel: AIModelConfig?
    private var voiceModels: [AIModelConfig] {
        AIModelConfig.defaultModels.filter { $0.modelType == .voice }
    }

    private var languageModels: [AIModelConfig] {
        AIModelConfig.defaultModels.filter { $0.modelType == .language }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
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
            }
            .padding(WaveTheme.spacingXL)
        }
        .sheet(item: $selectedModel) { model in
            ModelDetailSheet(model: model)
        }
    }

    // MARK: - Featured Carousel

    private var featuredCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WaveTheme.spacingMD) {
                RecommendedComboCard(
                    title: "Best Accuracy",
                    subtitle: "Whisper + Claude",
                    description: "Highest quality transcription and rewriting",
                    tintColor: .purple.opacity(0.15),
                    accentColor: .purple
                )

                RecommendedComboCard(
                    title: "Fastest",
                    subtitle: "Deepgram + GPT",
                    description: "Low latency real-time performance",
                    tintColor: .orange.opacity(0.15),
                    accentColor: .orange
                )

                RecommendedComboCard(
                    title: "Budget",
                    subtitle: "Deepgram + GPT-mini",
                    description: "Cost-effective for everyday use",
                    tintColor: .green.opacity(0.15),
                    accentColor: .green
                )
            }
        }
        .scrollTargetBehavior(.viewAligned)
    }

    // MARK: - Model Section

    private func modelSection(title: String, description: String, models: [AIModelConfig]) -> some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("View all") {}
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(WaveTheme.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(WaveTheme.textTertiary)
            }

            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(WaveTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WaveTheme.spacingMD) {
                    ForEach(Array(models.enumerated()), id: \.element.id) { index, model in
                        ModelCard(model: model) {
                            selectedModel = model
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recommended Combo Card

struct RecommendedComboCard: View {
    let title: String
    let subtitle: String
    let description: String
    let tintColor: Color
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accentColor)
            Text(subtitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WaveTheme.textPrimary)
            Text(description)
                .font(.system(size: 12))
                .foregroundStyle(WaveTheme.textSecondary)
        }
        .padding(WaveTheme.spacingLG)
        .frame(width: 240, height: 120, alignment: .leading)
        .background(tintColor)
        .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusMD))
        .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
    }
}

// MARK: - Model Detail Sheet

struct ModelDetailSheet: View {
    let model: AIModelConfig
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var isSaving = false
    @State private var saved = false

    var body: some View {
        VStack(alignment: .leading, spacing: WaveTheme.spacingXL) {
            // Header
            HStack {
                ProviderIcon(model: model, size: 20)
                    .frame(width: 36, height: 36)
                    .background(model.providerColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: WaveTheme.radiusInner))

                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .font(.system(size: 16, weight: .bold))
                    Text("by \(model.provider)")
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textSecondary)
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(WaveTheme.textTertiary)
                        .frame(width: 24, height: 24)
                        .background(WaveTheme.surfaceSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Description
            Text(model.description)
                .font(.system(size: 13))
                .foregroundStyle(WaveTheme.textSecondary)

            Divider()

            // API Key
            VStack(alignment: .leading, spacing: WaveTheme.spacingSM) {
                Text("\(model.provider) API Key")
                    .font(.system(size: 13, weight: .medium))

                SecureField("Enter your API key...", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Activate") {
                        saveApiKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)

                    if saved {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(WaveTheme.spacingXL)
        .frame(width: 400)
        .onAppear { loadExistingKey() }
    }

    private func loadExistingKey() {
        switch model.provider {
        case "OpenAI":
            apiKey = (try? KeychainManager.shared.getOpenAIKey()) ?? ""
        case "Anthropic":
            apiKey = (try? KeychainManager.shared.getAnthropicKey()) ?? ""
        case "Deepgram":
            apiKey = (try? KeychainManager.shared.getDeepgramKey()) ?? ""
        default:
            break
        }
    }

    private func saveApiKey() {
        switch model.provider {
        case "OpenAI":
            try? KeychainManager.shared.setOpenAIKey(apiKey)
        case "Anthropic":
            try? KeychainManager.shared.setAnthropicKey(apiKey)
        case "Deepgram":
            try? KeychainManager.shared.setDeepgramKey(apiKey)
        default:
            break
        }
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
    }

}
