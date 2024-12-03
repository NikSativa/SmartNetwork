import Foundation

// MARK: - Plugins.Curl

public extension Plugins {
    /// A plugin that logs the request in the `curl` format.
    final class Curl: Plugin {
        #if swift(>=6.0)
        /// The logging function.
        public typealias Logging = @Sendable (_ component: Component, _ id: String, _ url: () -> String, _ text: () -> String?) -> Void
        /// The logging function.
        public typealias SimpleLogging = @Sendable (_ component: Component, _ text: () -> String?) -> Void
        #else
        /// The logging function.
        public typealias Logging = (_ component: Component, _ id: String, _ url: () -> String, _ text: () -> String?) -> Void
        /// The logging function.
        public typealias SimpleLogging = (_ component: Component, _ text: () -> String?) -> Void
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

        public init(id: AnyHashable? = nil,
                    priority: PluginPriority = .curl,
                    options: Options = .all,
                    logger: @escaping SimpleLogging) {
            self.id = id ?? Self.makeHash()
            self.priority = priority
            self.logger = { component, _, _, text in
                logger(component, text)
            }
            self.options = options
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, session: SmartURLSession) {}
        public func verify(data: RequestResult, userInfo: UserInfo) throws {}
        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo, session: SmartURLSession) {
            guard options.contains(.willSend) else {
                return
            }

            let id = userInfo.uniqueID.uuidString
            let url: () -> String = {
                return (try? userInfo.smartRequestAddress?.url() ?? request.url)?.absoluteString ?? "< no url >"
            }

            logger(.phase, id, url) {
                "willSend"
            }

            logger(.curl, id, url) {
                let curl = request.cURLDescription(with: session)
                return curl
            }
        }

        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {
            guard options.contains(.didReceive) else {
                return
            }

            let id = userInfo.uniqueID.uuidString
            let url: () -> String = {
                return (try? userInfo.smartRequestAddress?.url() ?? request.url)?.absoluteString ?? "< no url >"
            }

            logger(.phase, id, url) {
                "didReceive"
            }

            logger(.curl, id, url) {
                let curl = data.cURLDescription()
                return curl
            }

            logger(.error, id, url) {
                let error = data.error?.requestError.subname
                return error
            }

            logger(.body, id, url) {
                let body = makeResponseBody(data.body)
                return body
            }
        }

        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {
            guard options.contains(.didFinish) else {
                return
            }

            let id = userInfo.uniqueID.uuidString
            let url: () -> String = {
                return (try? userInfo.smartRequestAddress?.url() ?? data.url)?.absoluteString ?? "< no url >"
            }

            logger(.phase, id, url) {
                "didFinish"
            }

            logger(.curl, id, url) {
                let curl = data.cURLDescription()
                return curl
            }

            logger(.error, id, url) {
                let error = data.error?.requestError.subname
                return error
            }

            logger(.body, id, url) {
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
