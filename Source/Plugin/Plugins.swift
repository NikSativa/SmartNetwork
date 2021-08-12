import Foundation

public enum Plugins {
    public enum TokenType {
        public enum Operation {
            case set(String)
            case add(String)
        }
        case header(Operation)
        case queryParam(String)
    }

    public final class Bearer: TokenPlugin {
        public required init(tokenProvider: @escaping Plugins.TokenPlugin.TokenProvider) {
            super.init(type: .header(.set("Authorization")),
                       tokenProvider: {
                        return tokenProvider().map { token in
                            return "Bearer " + token
                        }
                       })
        }
    }

    public final class StatusCode: Plugin {
        public init() {
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestable) {
        }

        public func willSend(_ parameters: Parameters, request: URLRequestable) {
        }

        public func didFinish(_ parameters: Parameters, request: URLRequestable, data: ResponseData) {
        }

        public func verify(data: ResponseData) throws {
            if let error = NRequest.StatusCode(data.statusCode) {
                throw error
            }
        }
    }

    open class TokenPlugin: Plugin {
        public typealias TokenProvider = () -> String?
        private let tokenProvider: TokenProvider
        private let type: TokenType
        
        public init(type: TokenType,
                    tokenProvider: @escaping TokenProvider) {
            self.tokenProvider = tokenProvider
            self.type = type
        }

        public func prepare(_ parameters: Parameters,
                            request: inout URLRequestable) {
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
                    queryItems = queryItems.filter({ $0.name != key })
                    queryItems.append(URLQueryItem(name: key, value: value))
                    urlComponents.queryItems = queryItems

                    if let url = urlComponents.url {
                        request.url = url
                    }
                }
            }
        }

        public func willSend(_ parameters: Parameters, request: URLRequestable) {
        }

        public func didFinish(_ parameters: Parameters, request: URLRequestable, data: ResponseData) {
        }

        public func verify(data: ResponseData) throws {
        }
    }
}
