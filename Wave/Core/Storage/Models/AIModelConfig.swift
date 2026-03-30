import Foundation
import SwiftUI

struct AIModelConfig: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var provider: String
    var modelType: ModelType
    var description: String
    var isFavorite: Bool

    enum ModelType: String, CaseIterable, Codable {
        case voice = "Voice"
        case language = "Language"
    }

    init(id: String = UUID().uuidString, name: String, provider: String, modelType: ModelType, description: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.provider = provider
        self.modelType = modelType
        self.description = description
        self.isFavorite = isFavorite
    }

    // MARK: - Provider Display (single source of truth)

    var providerIconName: String {
        switch provider {
        case "Anthropic": return "anthropic_icon"
        case "OpenAI": return "openai_icon"
        case "Deepgram": return "deepgram_icon"
        case "Google": return "google_icon"
        default: return "cpu"
        }
    }

    /// Fallback SF Symbol when asset isn't bundled
    var providerSystemIcon: String {
        switch provider {
        case "Anthropic": return "triangle.fill"
        case "OpenAI": return "circle.hexagongrid"
        case "Deepgram": return "waveform.circle"
        case "Google": return "sparkle"
        default: return "cpu"
        }
    }

    var providerColor: Color {
        switch provider {
        case "Anthropic": return .orange
        case "OpenAI": return .green
        case "Deepgram": return .blue
        case "Google": return .cyan
        default: return .gray
        }
    }

    var transcriptionProvider: TranscriptionProviderType? {
        switch name {
        case "Deepgram Nova-2": return .deepgram
        case "Whisper Large V3": return .whisper
        default: return nil
        }
    }

    var rewriteProvider: RewriteProviderType? {
        switch name {
        case "Claude Sonnet 4.6", "Claude Haiku 4.5": return .claude
        case "GPT-4o", "GPT-4o Mini": return .gpt
        default: return nil
        }
    }

    static let defaultModels: [AIModelConfig] = [
        // Voice models
        AIModelConfig(name: "Deepgram Nova-2", provider: "Deepgram", modelType: .voice, description: "High accuracy streaming speech recognition with low latency."),
        AIModelConfig(name: "Whisper Large V3", provider: "OpenAI", modelType: .voice, description: "Most accurate batch transcription model. Supports 100+ languages."),

        // Language models
        AIModelConfig(name: "Claude Sonnet 4.6", provider: "Anthropic", modelType: .language, description: "Latest Claude model with excellent writing quality and instruction following."),
        AIModelConfig(name: "Claude Haiku 4.5", provider: "Anthropic", modelType: .language, description: "Fast and cost-effective Claude model for quick text cleanup."),
        AIModelConfig(name: "GPT-4o", provider: "OpenAI", modelType: .language, description: "OpenAI's most capable model for text rewriting and cleanup."),
        AIModelConfig(name: "GPT-4o Mini", provider: "OpenAI", modelType: .language, description: "Fast, affordable OpenAI model for lightweight text cleanup."),
        AIModelConfig(name: "Gemini 2.5 Flash", provider: "Google", modelType: .language, description: "Google's fast and cost-efficient model for quick text cleanup."),
    ]
}

// MARK: - Provider Icon View (tries asset, falls back to SF Symbol)

struct ProviderIcon: View {
    let model: AIModelConfig
    var size: CGFloat = 16

    var body: some View {
        Group {
            if let nsImage = NSImage(named: model.providerIconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: model.providerSystemIcon)
                    .font(.system(size: size))
                    .foregroundStyle(model.providerColor)
            }
        }
    }
}
