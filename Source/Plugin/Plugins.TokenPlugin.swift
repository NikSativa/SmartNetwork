import Foundation

public extension Plugins {
    typealias TokenProvider = () -> String?

    enum TokenType {
        public enum Operation {
            case set(String)
            case add(String)
        }

        case header(Operation)
        case queryParam(String)
    }

    final class TokenPlugin: Plugin {
        private let tokenProvider: TokenProvider
        private let type: TokenType

        public init(type: TokenType,
                    tokenProvider: @escaping TokenProvider) {
            self.tokenProvider = tokenProvider
            self.type = type
        }

        public func prepare(_ parameters: Parameters,
                            request: inout URLRequestRepresentation,
                            userInfo: inout Parameters.UserInfo) {
            guard let value = tokenProvider() else {
                return
            }

            switch type {
            case .header(let operation):
                switch operation {
                case .set(let key):
                    request.setValue(value, forHTTPHeaderField: key)
                case .add(let key):
                    request.addValue(value, forHTTPHeaderField: key)
                }
            case .queryParam(let key):
                if let requestURL = request.url, var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
                    var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
                    queryItems = queryItems.filter { $0.name != key }
                    queryItems.append(URLQueryItem(name: key, value: value))
                    urlComponents.queryItems = queryItems

                    if let url = urlComponents.url {
                        request.url = url
                    }
                }
            }
        }

        public func verify(data: RequestResult, userInfo: Parameters.UserInfo) throws {}
    }
}
