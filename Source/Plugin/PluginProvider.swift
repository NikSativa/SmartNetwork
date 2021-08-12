import Foundation

// sourcery: fakable
public protocol PluginProvider {
    func plugins() -> [Plugin]
}

public struct PluginProviderContext: PluginProvider {
    private let cache: [Plugin]
    private let providers: [PluginProvider]

    public init(plugins: [Plugin] = [],
                providers: [PluginProvider] = []) {
        self.cache = plugins
        self.providers = providers
    }

    public func plugins() -> [Plugin] {
        return cache + providers.flatMap { $0.plugins() }
    }
}
