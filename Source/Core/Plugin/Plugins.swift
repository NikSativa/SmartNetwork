import Foundation

public protocol ErrorMapping: Error {
    static func verify(_ code: Int?) throws
}

public protocol AuthTokenProvider {
    func token() -> String?
}

public enum Plugins {
    public enum Bearer {
        public final class Storage: TokenPlugin {
            public init(authToken: TokenStorage) {
                super.init(type: .header(.set("Authorization")), tokenProvider: { () -> String? in
                    return authToken.token.map {
                        return "Bearer " + $0
                    }
                })
            }
        }

        public final class Provider: TokenPlugin {
            required init(authTokenProvider: AuthTokenProvider) {
                super.init(type: .header(.set("Authorization"))) { () -> String? in
                    return authTokenProvider.token().map {
                        return "Bearer " + $0
                    }
                }
            }
        }
    }

    public final class AutoError<E: ErrorMapping>: Plugin {
        public init() { }

        public func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
            try E.verify(code)
        }
    }

    public typealias StatusCode = AutoError<NRequest.StatusCode>

    public class TokenPlugin: Plugin {
        public enum TokenType {
            public enum Operation {
                case set(String)
                case add(String)
            }
            case header(Operation)
            case queryParam(String)
        }

        public typealias TokenProviderClosure = () -> String?
        private let tokenProvider: TokenProviderClosure
        private let type: TokenType

        public init(type: TokenType, tokenProvider: @escaping TokenProviderClosure) {
            self.tokenProvider = tokenProvider
            self.type = type
        }

        public func prepare(_ info: Info) -> URLRequest {
            guard let apiKey = tokenProvider() else {
                return info.request
            }

            var urlRequest = info.request

            switch type {
            case .header(let operation):
                switch operation {
                case .set(let keyName):
                    urlRequest.setValue(apiKey, forHTTPHeaderField: keyName)
                case .add(let keyName):
                    urlRequest.addValue(apiKey, forHTTPHeaderField: keyName)
                }
            case .queryParam(let keyName):
                if let requestURL = urlRequest.url, var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
                    var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
                    queryItems = queryItems.filter({ $0.name != keyName })
                    queryItems.append(URLQueryItem(name: keyName, value: apiKey))
                    urlComponents.queryItems = queryItems

                    if let url = urlComponents.url {
                        urlRequest.url = url
                    }
                }
            }

            return urlRequest
        }

        public func verify(httpStatusCode code: Int?, header: [AnyHashable : Any], data: Data?, error: Error?) throws {
        }
    }
}
