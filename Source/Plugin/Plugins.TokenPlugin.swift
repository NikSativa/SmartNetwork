import Foundation

public extension Plugins {
    #if swift(>=6.0)
    /// A closure that asynchronously provides a token string to be added to the request.
    typealias TokenProvider = @Sendable () async -> String?
    #else
    /// A closure that asynchronously provides a token string to be added to the request.
    typealias TokenProvider = () async -> String?
    #endif

    /// Defines where and how a token should be applied to an outgoing request.
    enum TokenType: SmartSendable {
        /// Defines operation applied to target header/query field.
        public enum Operation: SmartSendable {
            /// Sets the token unconditionally, replacing any existing value.
            case set(String)
            /// Sets the token only if the header or query parameter is not already present.
            case trySet(String)
            /// Appends the token to an existing header or query parameter.
            case add(String)
        }

        /// Add/Set a token to the header of the request.
        case header(Operation)
        /// Add/Set a token as a query parameter of the request.
        case queryParam(Operation)
    }

    /// A plugin that attaches a token to outgoing requests.
    ///
    /// Tokens can be injected into HTTP headers or query parameters using various strategies.
    /// The plugin fetches the token asynchronously and modifies the request before it is sent.
    actor TokenPlugin: Plugin {
        public nonisolated let id: ID
        public nonisolated let priority: PluginPriority

        private let tokenProvider: TokenProvider
        private let type: TokenType

        /// Creates token plugin.
        ///
        /// - Parameters:
        ///   - id: Unique plugin identifier.
        ///   - priority: Plugin execution priority.
        ///   - type: Where and how token should be inserted.
        ///   - tokenProvider: Async token source closure.
        public init(id: ID,
                    priority: PluginPriority,
                    type: TokenType,
                    tokenProvider: @escaping TokenProvider) {
            self.id = id
            self.priority = priority
            self.tokenProvider = tokenProvider
            self.type = type
        }

        /// Modifies the request by attaching a token to its header or query string, based on the configured type and operation.
        public func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async throws {
            let value = await tokenProvider()

            switch type {
            case let .header(operation):
                switch operation {
                case let .set(key):
                    request.setValue(value, forHTTPHeaderField: key)

                case let .trySet(key):
                    if request.value(forHTTPHeaderField: key) == nil {
                        request.setValue(value, forHTTPHeaderField: key)
                    }

                case let .add(key):
                    if let value {
                        request.addValue(value, forHTTPHeaderField: key)
                    }
                }

            case let .queryParam(operation):
                if let requestURL = request.url, var urlComponents = URLComponents(url: requestURL, resolvingAgainstBaseURL: false) {
                    var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []

                    switch operation {
                    case let .set(key):
                        queryItems = queryItems.filter { $0.name != key }
                        queryItems.append(URLQueryItem(name: key, value: value))

                    case let .trySet(key):
                        if !queryItems.contains(where: { $0.name == key }) {
                            queryItems.append(URLQueryItem(name: key, value: value))
                        }

                    case let .add(key):
                        queryItems.append(URLQueryItem(name: key, value: value))
                    }

                    urlComponents.queryItems = queryItems

                    if let url = urlComponents.url {
                        request.url = url
                    }
                }
            }
        }

        public func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {}
        public func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, response: SmartResponse) {}
        public func verify(parameters: Parameters, userInfo: UserInfo, response: SmartResponse) async throws {}
        public func didFinish(parameters: Parameters, userInfo: UserInfo, response: SmartResponse) {}
    }
}
