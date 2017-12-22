import Foundation

public protocol Plugin {
    typealias Info = (request: URLRequest, parameters: Parameters)

    func prepare(_ info: Info) -> URLRequest
    func willSend(_ info: Info)
    func didComplete(_ info: Info, response: Any?, error: Error?)

    /// including 'cancel'
    func didStop(_ info: Info)

    func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws
    func map(data: Data) -> Data
}

public extension Plugin {
    func prepare(_ info: Info) -> URLRequest {
        return info.request
    }

    func willSend(_ info: Info) { }
    func didComplete(_ info: Info, response: Any?, error: Error?) { }
    func didStop(_ info: Info) { }

    func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws { }
    func map(data: Data) -> Data {
        return data
    }
}

open class TokenPlugin: Plugin {
    public enum TokenType {
        case header(String)
        case queryParam(String)
    }

    public typealias TokenProvider = () -> String?
    private let tokenProvider: TokenProvider
    private let type: TokenType

    public init(type: TokenType, tokenProvider: @escaping TokenProvider) {
        self.tokenProvider = tokenProvider
        self.type = type
    }

    open func prepare(_ info: Info) -> URLRequest {
        guard let apiKey = tokenProvider() else {
            return info.request
        }

        var urlRequest = info.request

        switch type {
        case .header(let keyName):
            urlRequest.addValue(apiKey, forHTTPHeaderField: keyName)
            return urlRequest

        case .queryParam(let keyName):
            guard let requestURL = urlRequest.url, var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) else {
                assert(false, "Failed to create URLComponents from URLRequest")
                return urlRequest
            }

            var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
            queryItems.append(URLQueryItem(name: keyName, value: apiKey))
            urlComponents.queryItems = queryItems

            guard let url = urlComponents.url else {
                assert(false, "Failed to create new URLRequest")
                return urlRequest
            }

            urlRequest.url = url
            return urlRequest
        }
    }
}
