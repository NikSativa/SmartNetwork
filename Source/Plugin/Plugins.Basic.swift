import Foundation

public extension Plugins {
    /// Represents credentials used for HTTP Basic Authentication.
    ///
    /// When applied, the `username` and `password` are Base64-encoded and added to the request’s `Authorization` header
    /// in the format: `Authorization: Basic <base64(username:password)>`.
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
    /// A closure that provides an `AuthBasicToken` instance or `nil` if credentials are unavailable.
    typealias AuthBasicTokenProvider = @Sendable () -> AuthBasicToken?
    #else
    /// A closure that provides an `AuthBasicToken` instance or `nil` if credentials are unavailable.
    typealias AuthBasicTokenProvider = () -> AuthBasicToken?
    #endif

    /// Creates a plugin that adds HTTP Basic Authentication to outgoing requests.
    ///
    /// Uses the provided token provider to generate a Base64-encoded `Authorization` header.
    ///
    /// - Parameters:
    ///   - overrideExisting: If `true`, replaces any existing `Authorization` header.
    ///   - tokenProvider: A closure that returns `AuthBasicToken` credentials.
    /// - Returns: A `Plugin` that adds a `Basic` auth header to the request.
    static func AuthBasic(overrideExisting: Bool = true, with tokenProvider: @escaping AuthBasicTokenProvider) -> Plugin {
        return TokenPlugin(id: "AuthBasic",
                           priority: .authBasic,
                           type: .header(overrideExisting ? .set("Authorization") : .trySet("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { token in
                                   let token = Data("\(token.username):\(token.password)".utf8).base64EncodedString()
                                   return "Basic " + token
                               }
                           })
    }
}
