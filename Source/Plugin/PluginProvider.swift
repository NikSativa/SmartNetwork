import Foundation

public protocol PluginProviding {
    func plugins() -> [Plugin]
}

public struct PluginProvider {
    private let cache: [Plugin]
    private let providers: [PluginProviding]

    private init(plugins: [Plugin] = [],
                 providers: [PluginProviding] = []) {
        self.cache = plugins
        self.providers = providers
    }

    public static func create(plugins: [Plugin] = [],
                              providers: [PluginProviding] = []) -> PluginProviding {
        return Self(plugins: plugins,
                    providers: providers)
    }
}

// MARK: - PluginProviding

extension PluginProvider: PluginProviding {
    public func plugins() -> [Plugin] {
        return cache + providers.flatMap { $0.plugins() }
    }
}
