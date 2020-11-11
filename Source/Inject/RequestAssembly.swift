import Foundation

import NInject
#if SWIFT_PACKAGE
import NRequest
#endif

public class RequestAssembly: Assembly {
    public init() {
    }

    public func assemble(with registrator: Registrator) {
        registrator.register(AnyRequestFactory<RequestError>.self, options: .container + .open) { resolver, args in
            let pluginProvider = args.optionalFirst(PluginProvider.self) ?? resolver.optionalResolve()
            let refreshToken = args.optionalFirst(AnyRefreshToken<RequestError>.self) ?? resolver.optionalResolve()
            let factory = BaseRequestFactory<RequestError>(pluginProvider: pluginProvider,
                                                           refreshToken: refreshToken)
            return factory.toAny()
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
