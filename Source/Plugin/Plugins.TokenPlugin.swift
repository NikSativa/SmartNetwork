import Foundation

public extension Plugins {
    #if swift(>=6.0)
    /// The token provider.
    typealias TokenProvider = () -> String?
    #else
    /// The token provider.
    typealias TokenProvider = () -> String?
    #endif

    /// The type of the plugin where the token will be applied.
    enum TokenType {
        public enum Operation {
            /// Set token to the request. The previous value will be rewriten.
            case set(String)
            /// Add token to the request. The new value will be added to the existing one.
            case add(String)
        }

        /// Add/Set a token to the header of the request.
        case header(Operation)
        /// Add/Set a token as a query parameter of the request.
        case queryParam(Operation)
    }

    /// A plugin that adds a token to the request.
    /// The token can be added to the header or as a query parameter.
    /// The token will be added to the request before it is sent.
    final class TokenPlugin: Plugin {
        public let id: AnyHashable
        public let priority: PluginPriority

        private let tokenProvider: TokenProvider
        private let type: TokenType

        public init(id: AnyHashable,
                    priority: PluginPriority,
                    type: TokenType,
                    tokenProvider: @escaping TokenProvider) {
            self.id = id
            self.priority = priority
            self.tokenProvider = tokenProvider
            self.type = type
        }

        public func prepare(_ parameters: Parameters,
                            request: inout URLRequestRepresentation) {
            let value = tokenProvider()

            switch type {
            case .header(let operation):
                switch operation {
                case .set(let key):
                    request.setValue(value, forHTTPHeaderField: key)
                case .add(let key):
                    if let value {
                        request.addValue(value, forHTTPHeaderField: key)
                    }
                }
            case .queryParam(let operation):
                if let requestURL = request.url, var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
                    var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []

                    switch operation {
                    case .set(let key):
                        queryItems = queryItems.filter { $0.name != key }
                        queryItems.append(URLQueryItem(name: key, value: value))
                    case .add(let key):
                        queryItems.append(URLQueryItem(name: key, value: value))
                    }

                    urlComponents.queryItems = queryItems

                    if let url = urlComponents.url {
                        request.url = url
                    }
                }
            }
        }

        public func verify(data: RequestResult, userInfo: UserInfo) throws {}
        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {}
        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo) {}
        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}
    }
}

#if swift(>=6.0)
extension Plugins.TokenType: Sendable {}
extension Plugins.TokenType.Operation: Sendable {}
extension Plugins.TokenPlugin: @unchecked Sendable {}
#endif
