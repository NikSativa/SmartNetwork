import Foundation

public extension Plugins {
    typealias BasicTokenProvider = () -> (username: String, password: String)?

    static func Basic(with tokenProvider: @escaping BasicTokenProvider) -> Plugin {
        return TokenPlugin(type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { username, password in
                                   let token = Data("\(username):\(password)".utf8).base64EncodedString()
                                   return "Basic " + token
                               }
                           })
    }
}
