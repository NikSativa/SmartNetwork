import Foundation

public enum Plugins {
    public typealias TokenProvider = () -> String?

    public enum TokenType {
        public enum Operation {
            case set(String)
            case add(String)
        }

        case header(Operation)
        case queryParam(String)
    }

    public final class StatusCode: Plugin {
        init() {}

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, userInfo: inout Parameters.UserInfo) {}

        public func verify(data: ResponseData, userInfo: Parameters.UserInfo) throws {
            if let error = NRequest.StatusCode(data.statusCode) {
                throw error
            }
        }
    }

    public final class TokenPlugin: Plugin {
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

        public func verify(data: ResponseData, userInfo: Parameters.UserInfo) throws {}
    }

    public static func BearerPlugin(with tokenProvider: @escaping TokenProvider) -> Plugin {
        return TokenPlugin(type: .header(.set("Authorization")),
                           tokenProvider: {
                               return tokenProvider().map { token in
                                   return "Bearer " + token
                               }
                           })
    }
}
