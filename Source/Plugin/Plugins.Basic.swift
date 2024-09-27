import Foundation

public extension Plugins {
    #if swift(>=6.0)
    typealias BasicTokenProvider = @Sendable () -> (username: String, password: String)?
    #else
    typealias BasicTokenProvider = () -> (username: String, password: String)?
    #endif

    static func Basic(with tokenProvider: @escaping BasicTokenProvider) -> Plugin {
        return TokenPlugin(id: "Basic",
                           type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { username, password in
                                   let token = Data("\(username):\(password)".utf8).base64EncodedString()
                                   return "Basic " + token
                               }
                           })
    }
}
