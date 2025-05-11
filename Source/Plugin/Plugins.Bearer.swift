import Foundation

public extension Plugins {
    /// Creates a plugin that adds a Bearer token to the `Authorization` header of outgoing requests.
    ///
    /// This plugin uses the provided `tokenProvider` to asynchronously retrieve an access token, then formats it as a Bearer token
    /// (e.g., `"Bearer <token>"`) and injects it into the request's `Authorization` header.
    ///
    /// - Parameters:
    ///   - overrideExisting: If `true`, any existing `Authorization` header will be overwritten. If `false`, the token will only be set if the header is not already present.
    ///   - tokenProvider: A closure that asynchronously returns the token string.
    /// - Returns: A plugin that injects a Bearer token into the request.
    static func AuthBearer(overrideExisting: Bool = true, with tokenProvider: @escaping TokenProvider) -> Plugin {
        return TokenPlugin(id: "AuthBearer",
                           priority: .authBearer,
                           type: .header(overrideExisting ? .set("Authorization") : .trySet("Authorization")),
                           tokenProvider: {
                               return await tokenProvider().map { token in
                                   return "Bearer " + token
                               }
                           })
    }
}
