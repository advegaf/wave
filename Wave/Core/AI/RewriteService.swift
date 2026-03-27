import Foundation

final class RewriteService {
    private var providers: [RewriteProviderType: RewriteProvider] = [:]

    func registerProvider(_ provider: RewriteProvider) {
        providers[provider.providerType] = provider
    }

    func rewrite(text: String, context: RewriteContext, using providerType: RewriteProviderType) async throws -> String {
        guard let provider = providers[providerType] else {
            throw AIServiceError.noAPIKey(providerType.rawValue)
        }
        return try await provider.rewrite(text: text, context: context)
    }
}
