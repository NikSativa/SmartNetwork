import Foundation

// MARK: - Plugins.Curl

public extension Plugins {
    /// A plugin that logs the request in the `curl` format.
    final class Curl: Plugin {
        #if swift(>=6.0)
        /// The logging function.
        public typealias Logging = @Sendable (_ component: Component, _ text: () -> String?) -> Void
        #else
        /// The logging function.
        public typealias Logging = (_ component: Component, _ text: () -> String?) -> Void
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

            logger(.phase) {
                "willSend"
            }

            logger(.curl) {
                let curl = request.cURLDescription(with: session)
                return curl
            }
        }

        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {
            guard options.contains(.didReceive) else {
                return
            }

            logger(.phase) {
                "didReceive"
            }

            logger(.curl) {
                let curl = data.cURLDescription()
                return curl
            }

            logger(.error) {
                let error = data.error?.requestError.subname
                return error
            }

            logger(.body) {
                let body = makeResponseBody(data.body)
                return body
            }
        }

        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {
            guard options.contains(.didFinish) else {
                return
            }

            logger(.phase) {
                "didFinish"
            }

            logger(.curl) {
                let curl = data.cURLDescription()
                return curl
            }

            logger(.error) {
                let error = data.error?.requestError.subname
                return error
            }

            logger(.body) {
                let body = makeResponseBody(data.body)
                return body
            }
        }

        private func makeResponseBody(_ body: Data?) -> String {
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

public extension Plugins.Curl {
    /// The `curl` component of the log.
    enum Component {
        case phase
        case curl
        case error
        case body
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
        /// Logs all the phases.
        public static let all: Self = [.willSend, .didFinish, .didReceive]
    }
}

#if swift(>=6.0)
extension Plugins.Curl.Options: Sendable {}
#endif
