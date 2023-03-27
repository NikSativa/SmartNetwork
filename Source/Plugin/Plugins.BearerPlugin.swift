import Foundation

public extension Plugins {
    static func BearerPlugin(with tokenProvider: @escaping TokenProvider) -> Plugin {
        return TokenPlugin(type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { token in
                                   return "Bearer " + token
                               }
                           })
    }
}
