import Foundation

/// Stores API keys in UserDefaults for development.
/// For production, switch to Keychain with proper code signing to avoid password prompts.
final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()

    private let defaults = UserDefaults.standard
    private let prefix = "wave.apikey."

    func setKey(_ key: String, for provider: String) throws {
        defaults.set(key, forKey: prefix + provider)
    }

    func getKey(for provider: String) throws -> String? {
        defaults.string(forKey: prefix + provider)
    }

    func deleteKey(for provider: String) throws {
        defaults.removeObject(forKey: prefix + provider)
    }

    func hasKey(for provider: String) -> Bool {
        (try? getKey(for: provider)) != nil
    }

    func setDeepgramKey(_ key: String) throws {
        try setKey(key, for: TranscriptionProviderType.deepgram.keychainKey)
    }

    func setOpenAIKey(_ key: String) throws {
        try setKey(key, for: TranscriptionProviderType.whisper.keychainKey)
    }

    func setAnthropicKey(_ key: String) throws {
        try setKey(key, for: RewriteProviderType.claude.keychainKey)
    }

    func getDeepgramKey() throws -> String? {
        try getKey(for: TranscriptionProviderType.deepgram.keychainKey)
    }

    func getOpenAIKey() throws -> String? {
        try getKey(for: TranscriptionProviderType.whisper.keychainKey)
    }

    func getAnthropicKey() throws -> String? {
        try getKey(for: RewriteProviderType.claude.keychainKey)
    }
}
