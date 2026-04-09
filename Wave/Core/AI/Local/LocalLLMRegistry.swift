import Foundation
import MLXLLM
import MLXLMCommon

/// Wave's curated catalog of local instruct LLMs that ship as MLX-format weights
/// hosted on the `mlx-community` HuggingFace organization.
///
/// Every entry here corresponds to a `ModelConfiguration` already known to MLXLMCommon's
/// shared `LLMRegistry`, so we don't need to register custom model architectures.
struct LocalLLMEntry: Identifiable, Hashable, Sendable {
    /// Stable Wave-side identifier (used in `UserPreferences` and APIs).
    let id: String
    /// User-visible name shown in the Models Library.
    let displayName: String
    /// One-line description shown on cards and detail sheets.
    let description: String
    /// HuggingFace repo id, e.g. `mlx-community/Llama-3.2-3B-Instruct-4bit`.
    let huggingFaceId: String
    /// Approximate on-disk size after install (4-bit MLX weights + tokenizer).
    let approxDiskBytes: Int64
    /// Approximate runtime RAM footprint when loaded.
    let approxRAMBytes: Int64
    /// Whether this is the default model recommended for new users.
    let isRecommendedDefault: Bool
    /// Family tag for UI grouping / chat-template selection hints.
    let family: Family

    enum Family: String, Sendable {
        case llama
        case qwen
        case phi
    }

    /// Build a `MLXLMCommon.ModelConfiguration` for this entry.
    /// The shared `LLMRegistry` already knows most of these by id, so this
    /// just looks them up.
    func modelConfiguration() -> ModelConfiguration {
        // If the shared registry knows this id, use the curated configuration
        // (it carries `extraEOSTokens` and other quirks). Otherwise build a
        // minimal one from the id.
        if LLMRegistry.shared.contains(id: huggingFaceId) {
            return LLMRegistry.shared.configuration(id: huggingFaceId)
        }
        return ModelConfiguration(id: huggingFaceId)
    }
}

enum LocalLLMRegistry {

    /// Catalog ordered from smallest/fastest to largest/highest quality.
    /// Sizes are approximate; the real disk usage is reported by FileManager
    /// once installed.
    static let all: [LocalLLMEntry] = [
        LocalLLMEntry(
            id: "llama-3.2-1b-instruct-4bit",
            displayName: "Llama 3.2 1B Instruct",
            description: "Fastest and smallest. Best for the Light cleanup mode where speed matters more than richness.",
            huggingFaceId: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            approxDiskBytes: 750 * 1024 * 1024,
            approxRAMBytes: 1_200 * 1024 * 1024,
            isRecommendedDefault: false,
            family: .llama
        ),
        LocalLLMEntry(
            id: "llama-3.2-3b-instruct-4bit",
            displayName: "Llama 3.2 3B Instruct",
            description: "Balanced. Strong instruction following at a comfortable size for everyday dictation.",
            huggingFaceId: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            approxDiskBytes: 2_000 * 1024 * 1024,
            approxRAMBytes: 3_200 * 1024 * 1024,
            isRecommendedDefault: false,
            family: .llama
        ),
        LocalLLMEntry(
            id: "qwen3-4b-4bit",
            displayName: "Qwen 3 4B",
            description: "Alibaba's modern 4B model. Slightly larger than Llama 3 but excellent at concise rewriting.",
            huggingFaceId: "mlx-community/Qwen3-4B-4bit",
            approxDiskBytes: 2_500 * 1024 * 1024,
            approxRAMBytes: 4_000 * 1024 * 1024,
            isRecommendedDefault: false,
            family: .qwen
        ),
        LocalLLMEntry(
            id: "phi-3.5-mini-instruct-4bit",
            displayName: "Phi 3.5 Mini Instruct",
            description: "Default. Microsoft's small model — notably strong at strict instruction following, the most reliable choice for dictation cleanup.",
            huggingFaceId: "mlx-community/Phi-3.5-mini-instruct-4bit",
            approxDiskBytes: 2_200 * 1024 * 1024,
            approxRAMBytes: 3_500 * 1024 * 1024,
            isRecommendedDefault: true,
            family: .phi
        ),
        LocalLLMEntry(
            id: "qwen3-8b-4bit",
            displayName: "Qwen 3 8B",
            description: "Highest quality in the catalog. Slower per token; recommended for Heavy mode if your Mac has the headroom.",
            huggingFaceId: "mlx-community/Qwen3-8B-4bit",
            approxDiskBytes: 4_500 * 1024 * 1024,
            approxRAMBytes: 6_000 * 1024 * 1024,
            isRecommendedDefault: false,
            family: .qwen
        ),
    ]

    /// The default model id used until the user picks one.
    static var defaultModelId: String {
        all.first(where: { $0.isRecommendedDefault })?.id ?? all.first!.id
    }

    static func find(id: String) -> LocalLLMEntry? {
        all.first(where: { $0.id == id })
    }

    static func find(huggingFaceId: String) -> LocalLLMEntry? {
        all.first(where: { $0.huggingFaceId == huggingFaceId })
    }

    /// Best-effort check whether the model has been downloaded into the
    /// HuggingFace cache directory used by `defaultHubApi`. This is used by the
    /// Models Library UI to decide whether to show "Download" or "Set as active".
    ///
    /// Caches under `~/Library/Caches/huggingface/models--<org>--<repo>/` per
    /// HubApi convention. We just check for the snapshot directory's existence
    /// and a non-empty config.json — sufficient for UI state, not for guaranteeing
    /// every shard is on disk.
    static func isInstalled(_ entry: LocalLLMEntry) -> Bool {
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return false
        }
        // HubApi default cache layout: <caches>/huggingface/models/<org>/<repo>/
        let parts = entry.huggingFaceId.split(separator: "/")
        guard parts.count == 2 else { return false }
        let modelDir = cachesURL
            .appendingPathComponent("huggingface", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent(String(parts[0]), isDirectory: true)
            .appendingPathComponent(String(parts[1]), isDirectory: true)

        let configFile = modelDir.appendingPathComponent("config.json")
        return FileManager.default.fileExists(atPath: configFile.path)
    }

    /// Returns ids of every model currently installed on disk.
    static func installedIds() -> Set<String> {
        Set(all.filter(isInstalled).map(\.id))
    }

    /// Approximate total disk usage of installed models, by walking each model's
    /// cache directory. Returns 0 if nothing is installed.
    static func installedDiskBytes() -> Int64 {
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return 0
        }
        var total: Int64 = 0
        for entry in all where isInstalled(entry) {
            let parts = entry.huggingFaceId.split(separator: "/")
            guard parts.count == 2 else { continue }
            let modelDir = cachesURL
                .appendingPathComponent("huggingface", isDirectory: true)
                .appendingPathComponent("models", isDirectory: true)
                .appendingPathComponent(String(parts[0]), isDirectory: true)
                .appendingPathComponent(String(parts[1]), isDirectory: true)
            total += directorySize(at: modelDir)
        }
        return total
    }

    /// Delete the on-disk cache for a model. Caller is responsible for
    /// unloading the model from memory first via `LocalAIEngine`.
    static func uninstall(_ entry: LocalLLMEntry) throws {
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        let parts = entry.huggingFaceId.split(separator: "/")
        guard parts.count == 2 else { return }
        let modelDir = cachesURL
            .appendingPathComponent("huggingface", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent(String(parts[0]), isDirectory: true)
            .appendingPathComponent(String(parts[1]), isDirectory: true)

        if FileManager.default.fileExists(atPath: modelDir.path) {
            try FileManager.default.removeItem(at: modelDir)
        }
    }

    private static func directorySize(at url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else { continue }
            total += Int64(size)
        }
        return total
    }
}
