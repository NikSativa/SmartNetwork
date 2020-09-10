import Foundation
import NInject

public class RequestAssembly: Assembly {
    public init() { }

    public func assemble(with registrator: Registrator) {
        registrator.register(AnyRequestFactory<RequestError>.self, options: .transient) { resolver, args in
            resolver.resolve(BaseRequestFactory.self, with: args).toAny()
        }

        registrator.register(BaseRequestFactory<RequestError>.self, options: .transient) { resolver, args in
            BaseRequestFactory(pluginProvider: resolver.resolve(with: args))
        }

        registrator.register(Plugins.StatusCode.self, options: .transient, Plugins.StatusCode.init)

        registrator.register(Plugins.Bearer.Provider.self, options: .transient) { resolver in
            Plugins.Bearer.Provider(authTokenProvider: resolver.resolve())
        }

        registrator.register(Plugins.Bearer.Storage.self, options: .transient) { resolver, args in
            Plugins.Bearer.Storage(authToken: resolver.resolve(with: args))
        }

        registrator.register(TokenStorage.self, options: .transient) { resolver, args in
            Impl.TokenStorage(storage: resolver.resolve(), key: args[0])
        }

        registrator.register(Storage.self, options: .transient + .open) { resolver, args in
            UserDefaults.standard
        }
    }
}
