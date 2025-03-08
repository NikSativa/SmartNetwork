import Foundation

// MARK: - Plugins.Log

public extension Plugins {
    /// A plugin that logs the request lifecycle and helps to convert pure data to standard format.
    /// example cURL, body as pretty printed and sorted JSON etc.
    final class Log: Plugin {
        #if swift(>=6.0)
        /// The logging function.
        public typealias Logging = @Sendable (_ data: DataCollection) -> Void
        #else
        /// The logging function.
        public typealias Logging = (_ data: DataCollection) -> Void
        #endif

        public let id: ID
        public let priority: PluginPriority
        private let logger: Logging
        private let options: Options

        public init(id: ID? = nil,
                    priority: PluginPriority = .curl,
                    options: Options = .all,
                    logger: @escaping Logging) {
            self.id = id ?? Self.makeHash()
            self.priority = priority
            self.logger = logger
            self.options = options
        }

        public func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async {}
        public func verify(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) throws {}

        public func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {
            guard options.contains(.willSend) else {
                return
            }

            let collector: DataCollection = .init()
                .add(.id, userInfo.uniqueID)
                .add(.phase, Phase.willSend)
                .add(.userInfo, userInfo)
                .add(.parameters, parameters)
                .add(.request, request)
                .add(.headers, request.allHTTPHeaderFields ?? [:])
                .add(.url) {
                    return (try? userInfo.smartRequestAddress?.url() ?? request.url)?.absoluteString ?? "< no url >"
                }
                .add(.curl) {
                    let curl = request.cURLDescription(with: session)
                    return curl
                }

            logger(collector)
        }

        public func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, data: SmartResponse) {
            guard options.contains(.didReceive) else {
                return
            }

            let collector: DataCollection = .init()
                .add(.id, userInfo.uniqueID)
                .add(.phase, Phase.didReceive)
                .add(.userInfo, userInfo)
                .add(.parameters, parameters)
                .add(.request, request)
                .add(.result, data)
                .add(.headers, request.allHTTPHeaderFields ?? [:])
                .add(.url) {
                    return (try? userInfo.smartRequestAddress?.url() ?? request.url)?.absoluteString ?? "< no url >"
                }
                .add(.curl) {
                    let curl = data.cURLDescription()
                    return curl
                }
                .add(.error, if: data.error != nil) {
                    return data.error ?? RequestError.generic // generic will never happen
                }
                .add(.requestError, if: data.error != nil) {
                    let error = data.error?.requestError.subname
                    return error ?? "< no error >"
                }
                .add(.body, if: data.body != nil) {
                    let body = Self.makeResponseBody(data.body)
                    return body
                }

            logger(collector)
        }

        public func didFinish(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) {
            guard options.contains(.didFinish) else {
                return
            }

            let collector: DataCollection = .init()
                .add(.id, userInfo.uniqueID)
                .add(.phase, Phase.didFinish)
                .add(.userInfo, userInfo)
                .add(.result, data)
                .add(.headers, data.request?.allHTTPHeaderFields ?? [:])
                .add(.url) {
                    return (try? userInfo.smartRequestAddress?.url() ?? data.url)?.absoluteString ?? "< no url >"
                }
                .add(.curl) {
                    let curl = data.cURLDescription()
                    return curl
                }
                .add(.error, if: data.error != nil) {
                    return data.error ?? RequestError.generic // generic will never happen
                }
                .add(.requestError, if: data.error != nil) {
                    let error = data.error?.requestError.subname
                    return error ?? "< no error >"
                }
                .add(.body, if: data.body != nil) {
                    let body = Self.makeResponseBody(data.body)
                    return body
                }

            logger(collector)
        }

        public func wasCancelled(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {
            let collector: DataCollection = .init()
                .add(.id, userInfo.uniqueID)
                .add(.phase, Phase.wasCancelled)
                .add(.userInfo, userInfo)
                .add(.parameters, parameters)
                .add(.request, request)
                .add(.headers, request.allHTTPHeaderFields ?? [:])
                .add(.url) {
                    return (try? userInfo.smartRequestAddress?.url() ?? request.url)?.absoluteString ?? "< no url >"
                }
                .add(.curl) {
                    let curl = request.cURLDescription(with: session)
                    return curl
                }

            logger(collector)
        }

        private static func makeResponseBody(_ body: Data?) -> String {
            guard let body else {
                return "< nil >"
            }

            if body.isEmpty {
                return "< empty >"
            }

            let responseText: String
            do {
                let json = try JSONSerialization.jsonObject(with: body, options: [.allowFragments])
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
                if let prettyStr = String(data: prettyData, encoding: .utf8) {
                    responseText = prettyStr
                } else {
                    responseText = String(data: body, encoding: .utf8) ?? "< unexpected response >"
                }
            } catch {
                if let text = String(data: body, encoding: .utf8) {
                    responseText = text
                } else {
                    responseText = "< serialization error: " + error.localizedDescription + " >"
                }
            }

            return responseText
        }
    }
}

public extension Plugins.Log {
    /// The `curl` component of the log.
    struct Component: Hashable, RawRepresentable, ExpressibleByStringLiteral, CustomDebugStringConvertible, SmartSendable {
        public let rawValue: String
        /// The value is indicating the index the ``Component`` will iterated.
        public let sortingOrder: Int

        public init(rawValue: String) {
            self.rawValue = rawValue
            self.sortingOrder = -1
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
            self.sortingOrder = -1
        }

        init(rawValue: String, sortingOrder: Int) {
            self.rawValue = rawValue
            self.sortingOrder = sortingOrder
        }

        public static let phase: Self = .init(rawValue: "phase", sortingOrder: 0)
        public static let url: Self = .init(rawValue: "url", sortingOrder: 10)
        public static let curl: Self = .init(rawValue: "curl", sortingOrder: 20)
        public static let error: Self = .init(rawValue: "error", sortingOrder: 30)
        public static let requestError: Self = .init(rawValue: "requestError", sortingOrder: 40)
        public static let body: Self = .init(rawValue: "body", sortingOrder: 50)
        public static let id: Self = "id"
        public static let headers: Self = "headers"
        public static let userInfo: Self = "userInfo"
        public static let parameters: Self = "parameters"
        public static let request: Self = "request"
        public static let result: Self = "result"

        public var debugDescription: String {
            return rawValue
        }
    }

    /// The `curl` phase of the log.
    struct Phase: Hashable, RawRepresentable, ExpressibleByStringLiteral, CustomDebugStringConvertible, SmartSendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        public static let willSend: Self = "willSend"
        public static let didReceive: Self = "didReceive"
        public static let didFinish: Self = "didFinish"
        public static let wasCancelled: Self = "wasCancelled"

        public var debugDescription: String {
            return rawValue
        }
    }

    /// The options for the `Curl` plugin.
    struct Options: OptionSet, SmartSendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Logs the request before sending it.
        public static let willSend: Self = .init(rawValue: 1 << 0)
        /// Logs the response after receiving response.
        public static let didReceive: Self = .init(rawValue: 1 << 1)
        /// Logs the response after the request is finished.
        public static let didFinish: Self = .init(rawValue: 1 << 2)
        /// Logs the request after it was cancelled.
        public static let wasCancelled: Self = .init(rawValue: 1 << 2)
        /// Logs all phases.
        public static let all: Self = [.willSend, .didFinish, .didReceive, .wasCancelled]
    }

    struct DataCollection: Sequence, CustomDebugStringConvertible {
        public typealias Getter<T> = () -> T

        public let data: [Component: Getter<Any>]

        public init(data: [Component: Getter<Any>] = [:]) {
            self.data = data
        }

        public func add(_ key: Component, _ value: @autoclosure @escaping Getter<Any>) -> Self {
            var data = data
            data[key] = value
            return .init(data: data)
        }

        public func add(_ key: Component, _ value: @escaping Getter<Any>) -> Self {
            var data = data
            data[key] = value
            return .init(data: data)
        }

        public func add(_ key: Component, if condition: Bool, _ value: @escaping Getter<Any>) -> Self {
            guard condition else {
                return self
            }

            var data = data
            data[key] = value
            return .init(data: data)
        }

        public func getClosure(safe key: Component) -> Getter<Any>? {
            return data[key]
        }

        public func getClosure(_ key: Component) -> Getter<Any> {
            return data[key]!
        }

        public func getClosure<T>(safe key: Component, ofType: T.Type) -> Getter<T>? {
            if let value = data[key]?() as? T {
                return { [value] in
                    return value
                }
            }
            return nil
        }

        public func getClosure<T>(_ key: Component, ofType: T.Type) -> Getter<T> {
            return { [data] in
                return data[key]!() as! T
            }
        }

        public func get(safe key: Component) -> Any? {
            return data[key]?()
        }

        public func get(_ key: Component) -> Any {
            return data[key]!()
        }

        public func get<T>(safe key: Component, ofType: T.Type) -> T? {
            return data[key]?() as? T
        }

        public func get<T>(_ key: Component, ofType: T.Type) -> T {
            return data[key]?() as! T
        }

        public subscript<T>(safe key: Component, ofType type: T.Type) -> T? {
            return get(safe: key, ofType: type)
        }

        public subscript<T>(_ key: Component, ofType type: T.Type) -> T {
            return get(key, ofType: type)
        }

        public func makeIterator() -> Iterator {
            return .init(data: self)
        }

        public struct Iterator: IteratorProtocol {
            public typealias Element = (key: Component, value: Getter<Any>)

            private let data: [Element]
            private var index: Int

            init(data: DataCollection) {
                self.data = data.data.sorted(by: { a, b in
                    switch (a.key.sortingOrder, b.key.sortingOrder) {
                    case (-1, -1):
                        return a.key.rawValue < b.key.rawValue
                    case (-1, _):
                        return false
                    case (_, -1):
                        return true
                    default:
                        return a.key.sortingOrder < b.key.sortingOrder
                    }
                })
                self.index = 0
            }

            public mutating func next() -> Element? {
                if index < data.count {
                    let item = data[index]
                    index += 1
                    return item
                } else {
                    return nil
                }
            }
        }

        public var debugDescription: String {
            return data.mapValues {
                return $0()
            }.debugDescription
        }
    }
}
