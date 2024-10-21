import Foundation

public extension Plugins {
    /// The plugin that adds the `bearer` authentication token to the header.
    static func AuthBearer(with tokenProvider: @escaping TokenProvider) -> Plugin {
        return TokenPlugin(id: "AuthBearer",
                           priority: .authBearer,
                           type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { token in
                                   return "Bearer " + token
                               }
                           })
    }
}
