import Foundation

public protocol RequestFactory {
    func make(for parameters: Parameters,
              pluginContext: PluginProvider?) -> Request
}

extension Impl {
    final class RequestFactory {}
}

extension Impl.RequestFactory: RequestFactory {
    func make(for parameters: Parameters,
              pluginContext: PluginProvider?) -> Request {
        return Impl.Request(parameters: parameters,
                            pluginContext: pluginContext)
    }
}
