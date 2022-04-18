import Foundation

public class ModuleFactory {
    public init() {}

    public func factory() -> RequestFactory {
        return Impl.RequestFactory()
    }

    public func manager<Error: AnyError>(factory: RequestFactory? = nil,
                                         pluginProvider: PluginProvider? = nil,
                                         stopTheLine: AnyStopTheLine<Error>? = nil) -> AnyRequestManager<Error> {
        return Impl.RequestManager(factory: factory ?? self.factory(),
                                   pluginProvider: pluginProvider,
                                   stopTheLine: stopTheLine).toAny()
    }

    public func manager<Error: AnyError>(factory: RequestFactory? = nil,
                                         plugins: [Plugin],
                                         stopTheLine: AnyStopTheLine<Error>? = nil) -> AnyRequestManager<Error> {
        return manager(factory: factory ?? self.factory(),
                       pluginProvider: plugins.isEmpty ? nil : PluginProviderContext(plugins: plugins),
                       stopTheLine: stopTheLine).toAny()
    }

    public func statusCodePlugin() -> Plugin {
        return Plugins.StatusCode()
    }

    public func bearerPlugin(tokenProvider: @escaping Plugins.TokenProvider) -> Plugin {
        return Plugins.TokenPlugin(type: .header(.set("Authorization")),
                                   tokenProvider: {
                                       return tokenProvider().map { token in
                                           return "Bearer " + token
                                       }
                                   })
    }

    public func tokenPlugin(type: Plugins.TokenType,
                            tokenProvider: @escaping Plugins.TokenProvider) -> Plugin {
        return Plugins.TokenPlugin(type: type,
                                   tokenProvider: tokenProvider)
    }
}
