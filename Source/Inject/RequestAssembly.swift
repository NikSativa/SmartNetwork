import Foundation

import NInject
#if SWIFT_PACKAGE
import NRequest
#endif

public class RequestAssembly: Assembly {
    public init() { }

    public func assemble(with registrator: Registrator) {
        registrator.register(AnyRequestFactory<RequestError>.self, options: .transient) { resolver, args in
            resolver.resolve(BaseRequestFactory.self, with: args).toAny()
        }

        registrator.register(BaseRequestFactory<RequestError>.self, options: .transient) { resolver, args in
            BaseRequestFactory(pluginProvider: args.optionalFirst(PluginProvider.self) ?? resolver.resolve(with: args),
                               refreshToken: args.optionalFirst(AnyRefreshToken.self) ?? resolver.resolve(with: args))
        }

        registrator.register(Plugins.StatusCode.self, options: .transient, Plugins.StatusCode.init)

        registrator.register(Plugins.Bearer.self, options: .transient) { resolver, args in
            let tokenProvider: BearerTokenProvider = args.optionalFirst() ?? resolver.resolve()
            if let tokenType: Plugins.TokenType = args.optionalFirst() {
                return Plugins.Bearer(tokenProvider: tokenProvider, type: tokenType)
            }
            return Plugins.Bearer(tokenProvider: tokenProvider)
        }
    }
}
