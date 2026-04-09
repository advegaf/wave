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

    // MARK: - Provider Display (single source of truth)

    var providerIconName: String {
        switch provider {
        case "WhisperKit": return "whisperkit_icon"
        case "MLX": return "mlx_icon"
        default: return "cpu"
        }
    }

    /// Fallback SF Symbol when asset isn't bundled
    var providerSystemIcon: String {
        switch provider {
        case "WhisperKit": return "waveform.circle"
        case "MLX": return "cpu"
        default: return "cpu"
        }
    }

    var providerColor: Color {
        switch provider {
        case "WhisperKit": return .blue
        case "MLX": return .teal
        default: return .gray
        }
    }

    var transcriptionProvider: TranscriptionProviderType? {
        switch name {
        case "WhisperKit (Local)": return .whisperKit
        default: return nil
        }
    }

    var rewriteProvider: RewriteProviderType? {
        // All language entries are local LLMs in the Wave-side LocalLLMRegistry.
        // Card activation looks them up by Wave-side id, not by provider type.
        modelType == .language ? .localLLM : nil
    }

    /// Wave-side `LocalLLMEntry.id` for language models. Used by ModelsLibraryView
    /// to wire each card to its install / activate / delete actions.
    var localLLMId: String? {
        guard modelType == .language else { return nil }
        return LocalLLMRegistry.find(huggingFaceId: huggingFaceId ?? "")?.id
    }

    /// HuggingFace repo id for language models, e.g. `mlx-community/Llama-3.2-3B-Instruct-4bit`.
    var huggingFaceId: String? = nil

    init(
        id: String = UUID().uuidString,
        name: String,
        provider: String,
        modelType: ModelType,
        description: String,
        isFavorite: Bool = false,
        huggingFaceId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.modelType = modelType
        self.description = description
        self.isFavorite = isFavorite
        self.huggingFaceId = huggingFaceId
    }

    /// The catalog shown in `ModelsLibraryView`. Voice = WhisperKit (always
    /// installed). Language = the curated `LocalLLMRegistry` lineup, mapped 1:1
    /// so the existing UI shape is preserved.
    static var defaultModels: [AIModelConfig] {
        var models: [AIModelConfig] = [
            AIModelConfig(
                name: "WhisperKit (Local)",
                provider: "WhisperKit",
                modelType: .voice,
                description: "On-device speech recognition. Runs entirely on your Mac. No network required."
            ),
        ]

        for entry in LocalLLMRegistry.all {
            models.append(
                AIModelConfig(
                    name: entry.displayName,
                    provider: "MLX",
                    modelType: .language,
                    description: entry.description,
                    huggingFaceId: entry.huggingFaceId
                )
            )
        }
        return models
    }
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
