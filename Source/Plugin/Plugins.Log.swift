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

        #if swift(>=6.0)
        public nonisolated(unsafe) let id: AnyHashable
        #else
        public let id: AnyHashable
        #endif

        public let priority: PluginPriority
        private let logger: Logging
        private let options: Options

        public init(id: AnyHashable? = nil,
                    priority: PluginPriority = .curl,
                    options: Options = .all,
                    logger: @escaping Logging) {
            self.id = id ?? Self.makeHash()
            self.priority = priority
            self.logger = logger
            self.options = options
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, session: SmartURLSession) {}
        public func verify(data: RequestResult, userInfo: UserInfo) throws {}

        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo, session: SmartURLSession) {
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

        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {
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

        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {
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

        public func wasCancelled(_ parameters: Parameters, request: any URLRequestRepresentation, userInfo: UserInfo, session: any SmartURLSession) {
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
    struct Component: Hashable, RawRepresentable, ExpressibleByStringLiteral, CustomDebugStringConvertible {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }

        public static let id: Self = "id"
        public static let url: Self = "url"
        public static let phase: Self = "phase"
        public static let curl: Self = "curl"
        public static let headers: Self = "headers"
        public static let error: Self = "error"
        public static let requestError: Self = "requestError"
        public static let body: Self = "body"
        public static let userInfo: Self = "userInfo"
        public static let parameters: Self = "parameters"
        public static let request: Self = "request"
        public static let result: Self = "result"

        public var debugDescription: String {
            return rawValue
        }
    }

    /// The `curl` phase of the log.
    struct Phase: Hashable, RawRepresentable, ExpressibleByStringLiteral, CustomDebugStringConvertible {
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
    struct Options: OptionSet {
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

    struct DataCollection: Sequence {
        public typealias Getter = () -> Any

        public let data: [Component: Getter]

        public init(data: [Component: Getter] = [:]) {
            self.data = data
        }

        public func add(_ key: Component, _ value: @autoclosure @escaping Getter) -> Self {
            var data = data
            data[key] = value
            return .init(data: data)
        }

        public func add(_ key: Component, _ value: @escaping Getter) -> Self {
            var data = data
            data[key] = value
            return .init(data: data)
        }

        public func add(_ key: Component, if condition: Bool, _ value: @escaping Getter) -> Self {
            guard condition else {
                return self
            }

            var data = data
            data[key] = value
            return .init(data: data)
        }

        public func getClosure(safe key: Component) -> (() -> Any)? {
            return data[key]
        }

        public func getClosure(_ key: Component) -> () -> Any {
            return data[key]!
        }

        public func getAny(safe key: Component) -> Any? {
            return data[key]?()
        }

        public func getAny(_ key: Component) -> Any {
            return data[key]!()
        }

        public func get<T>(safe key: Component, ofType: T.Type = T.self) -> T? {
            return data[key]?() as? T
        }

        public func get<T>(_ key: Component, ofType: T.Type = T.self) -> T {
            return data[key]?() as! T
        }

        public subscript<T>(safe key: Component) -> T? {
            return get(safe: key)
        }

        public subscript<T>(_ key: Component) -> T {
            return get(key)
        }

        public func makeIterator() -> Iterator {
            return .init(data: self)
        }

        public struct Iterator: IteratorProtocol {
            public typealias Element = (key: Component, value: Getter)

            private let data: [Element]
            private var index: Int

            init(data: DataCollection) {
                self.data = data.data.sorted(by: { a, b in
                    return a.key.rawValue < b.key.rawValue
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
    }
}

#if swift(>=6.0)
extension Plugins.Log.Options: Sendable {}
extension Plugins.Log.Component: Sendable {}
extension Plugins.Log.Phase: Sendable {}
#endif
