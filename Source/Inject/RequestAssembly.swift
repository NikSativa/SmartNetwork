import Foundation
import NInject

public class RequestAssembly: Assembly {
    public init() { }

    public func assemble(with registrator: Registrator) {
        registrator.register(AnyRequestFactory<RequestError>.self, options: .transient) { resolver, args in
            resolver.resolve(BaseRequestFactory.self, with: args).toAny()
        }

        registrator.register(BaseRequestFactory<RequestError>.self, options: .transient) { resolver, args in
            BaseRequestFactory(pluginProvider: args.optionalResolve(PluginProvider.self, at: 0) ?? resolver.resolve(with: args))
        }

        registrator.register(Plugins.StatusCode.self, options: .transient, Plugins.StatusCode.init)

        registrator.register(Plugins.Bearer.Provider.self, options: .transient) { resolver, args in
            if let tokenType: Plugins.TokenType = args.optionalResolve(at: 0) {
                return Plugins.Bearer.Provider(authTokenProvider: resolver.resolve(), type: tokenType)
            }
            return Plugins.Bearer.Provider(authTokenProvider: resolver.resolve())
        }

        registrator.register(Plugins.Bearer.Storage.self, options: .transient) { resolver, args in
            let key: String = args[0]
            if let tokenType: Plugins.TokenType = args.optionalResolve(at: 1) {
                return Plugins.Bearer.Storage(authToken: resolver.resolve(with: [key]), type: tokenType)
            }
            return Plugins.Bearer.Storage(authToken: resolver.resolve(with: [key]))
        }

        registrator.register(UserDefaults.self, options: .container + .open) {
            UserDefaults.standard
        }

        registrator.register(Storages.UserDefaults.self, options: .transient + .open) {
            .init(storage: $0.resolve())
        }

        registrator.register(Storages.Keyed<String>.self, options: .container + .open) { resolver, args in
            let key: String = args[0]
            return Storages.Keyed(storage: resolver.resolve(), key: key)
        }

        registrator.register(AnyStorage<String, String>.self, options: .transient + .open) {
            $0.resolve(Storages.UserDefaults.self).toAny()
        }
    }
}
