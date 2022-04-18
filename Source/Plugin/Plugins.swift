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

    final class StatusCode: Plugin {
        init() {}

        func prepare(_: Parameters, request _: inout URLRequestable, userInfo _: inout Parameters.UserInfo) {}

        func willSend(_: Parameters, request _: URLRequestable) {}

        func didReceive(_ parameters: Parameters, data: ResponseData) {}

        func didFinish(_ parameters: Parameters, data: ResponseData, dto: Any?) {}

        func verify(data: ResponseData) throws {
            if let error = NRequest.StatusCode(data.statusCode) {
                throw error
            }
        }
    }

    final class TokenPlugin: Plugin {
        private let tokenProvider: TokenProvider
        private let type: TokenType

        init(type: TokenType,
             tokenProvider: @escaping TokenProvider) {
            self.tokenProvider = tokenProvider
            self.type = type
        }

        func prepare(_ parameters: Parameters,
                     request: inout URLRequestable,
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

        func willSend(_: Parameters, request _: URLRequestable) {}

        func didReceive(_ parameters: Parameters, data: ResponseData) {}

        func didFinish(_ parameters: Parameters, data: ResponseData, dto: Any?) {}

        func verify(data _: ResponseData) throws {}
    }
}
