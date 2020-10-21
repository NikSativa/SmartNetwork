import Foundation

public protocol ErrorMapping: Error {
    static func verify(_ code: Int?) throws
}

public protocol AuthTokenProvider {
    func token() -> String?
}

public enum Plugins {
    public enum TokenType {
        public enum Operation {
            case set(String)
            case add(String)
        }
        case header(Operation)
        case queryParam(String)
    }

    public enum Bearer {
        public final class Storage: TokenPlugin {
            public init(authToken: Storages.Keyed<String>, type: TokenType = .header(.set("Authorization"))) {
                super.init(type: type, tokenProvider: { () -> String? in
                    return authToken.value.map {
                        return "Bearer " + $0
                    }
                })
            }
        }

        public final class Provider: TokenPlugin {
            required public init(authTokenProvider: AuthTokenProvider, type: TokenType = .header(.set("Authorization"))) {
                super.init(type: type) { () -> String? in
                    return authTokenProvider.token().map {
                        return "Bearer " + $0
                    }
                }
            }
        }
    }

    public final class AutoError<E: ErrorMapping>: Plugin {
        public init() { }

        public func prepare(_ info: inout Info) {
        }

        public func willSend(_ info: Info) {
        }

        public func didFinish(_ info: Info, response: URLResponse?, with error: Error?, statusCode: Int?) {
        }

        public func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
            try E.verify(code)
        }
    }

    public typealias StatusCode = AutoError<NRequest.StatusCode>

    public class TokenPlugin: Plugin {
        public typealias TokenProviderClosure = () -> String?
        private let tokenProvider: TokenProviderClosure
        private let type: TokenType

        public init(type: TokenType, tokenProvider: @escaping TokenProviderClosure) {
            self.tokenProvider = tokenProvider
            self.type = type
        }

        public func willSend(_ info: Info) {
        }

        public func prepare(_ info: inout Info) {
            guard let apiKey = tokenProvider() else {
                return
            }

            switch type {
            case .header(let operation):
                switch operation {
                case .set(let keyName):
                    info.request.setValue(apiKey, forHTTPHeaderField: keyName)
                case .add(let keyName):
                    info.request.addValue(apiKey, forHTTPHeaderField: keyName)
                }
            case .queryParam(let keyName):
                if let requestURL = info.request.url, var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
                    var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
                    queryItems = queryItems.filter({ $0.name != keyName })
                    queryItems.append(URLQueryItem(name: keyName, value: apiKey))
                    urlComponents.queryItems = queryItems

                    if let url = urlComponents.url {
                        info.request.url = url
                    }
                }
            }
        }

        public func didFinish(_ info: Info, response: URLResponse?, with error: Error?, statusCode: Int?) {
        }

        public func verify(httpStatusCode code: Int?, header: [AnyHashable : Any], data: Data?, error: Error?) throws {
        }
    }
}
