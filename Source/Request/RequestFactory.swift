import Foundation

public protocol RequestFactory {
    func make(for parameters: Parameters,
              pluginContext: PluginProvider?) -> Request
}

// MARK: - Impl.RequestFactory

extension Impl {
    final class RequestFactory {}
}

// MARK: - Impl.RequestFactory + RequestFactory

extension Impl.RequestFactory: RequestFactory {
    func make(for parameters: Parameters,
              pluginContext: PluginProvider?) -> Request {
        return Impl.Request(parameters: parameters,
                            pluginContext: pluginContext)
    }
}
