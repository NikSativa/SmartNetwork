import Foundation

public protocol PluginProvider {
    func plugins() -> [Plugin]
}

public struct PluginProviderContext: PluginProvider {
    private let cache: [Plugin]

    public init(_ plugins: [Plugin]) {
        self.cache = plugins
    }

    public func plugins() -> [Plugin] {
        return cache
    }
}
