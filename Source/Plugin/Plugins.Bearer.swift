import Foundation

public extension Plugins {
    static func Bearer(with tokenProvider: @escaping TokenProvider) -> Plugin {
        return TokenPlugin(id: "Bearer",
                           type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { token in
                                   return "Bearer " + token
                               }
                           })
    }
}
