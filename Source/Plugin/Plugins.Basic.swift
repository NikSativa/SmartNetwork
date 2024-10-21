import Foundation

public extension Plugins {
    /// The basic authentication token.
    ///
    /// The `username` and `password` will be:
    /// - encoded to Base64
    /// - added to the header with the key `Authorization`.
    struct AuthBasicToken {
        /// The username.
        public let username: String
        /// The password
        public let password: String

        /// Creates a new instance of `AuthBasicToken`.
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }

    #if swift(>=6.0)
    /// The basic authentication token provider.
    typealias AuthBasicTokenProvider = @Sendable () -> AuthBasicToken?
    #else
    /// The basic authentication token provider.
    typealias AuthBasicTokenProvider = () -> AuthBasicToken?
    #endif

    /// The plugin that adds the basic authentication token to the header.
    static func AuthBasic(with tokenProvider: @escaping AuthBasicTokenProvider) -> Plugin {
        return TokenPlugin(id: "AuthBasic",
                           priority: .authBasic,
                           type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { token in
                                   let token = Data("\(token.username):\(token.password)".utf8).base64EncodedString()
                                   return "Basic " + token
                               }
                           })
    }
}

#if swift(>=6.0)
extension Plugins.AuthBasicToken: Sendable {}
#endif
