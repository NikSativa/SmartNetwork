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

        /// The `curl` component of the log.
        public enum Component {
            case curl
            case error
            case body
        }

        #if swift(>=6.0)
        public nonisolated(unsafe) let id: AnyHashable
        #else
        public let id: AnyHashable
        #endif

        public let priority: PluginPriority
        private let logger: Logging

        public init(id: AnyHashable? = nil,
                    priority: PluginPriority = .curl,
                    logger: @escaping Logging) {
            self.id = id ?? Self.makeHash()
            self.priority = priority
            self.logger = logger
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation) {}
        public func verify(data: RequestResult, userInfo: UserInfo) throws {}
        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo) {}
        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}

        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {
            logger(.curl) {
                let curl = makeCurl(for: data.request?.sdk)
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

        private func makeCurl(for request: URLRequest?) -> String? {
            guard let request,
                  let url = request.url,
                  let method = request.httpMethod else {
                return nil
            }

            var components = ["curl -v"]
            components.append("-X \(method)")

            let headers: HeaderFields = .init(request.allHTTPHeaderFields ?? [:])
            for header in headers {
                let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
                components.append("-H \"\(header.key): \(escapedValue)\"")
            }

            if let httpBodyData = request.httpBody {
                let httpBody = String(decoding: httpBodyData, as: UTF8.self)
                var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
                escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

                components.append("-d \"\(escapedBody)\"")
            }

            components.append("\"\(url.absoluteString)\"")

            let result = components.joined(separator: " \\\n\t")
            return result
        }

        private func makeResponseBody(_ body: Data?) -> String? {
            guard let body else {
                return nil
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

#if canImport(os)
import os

public extension PluginPriority {
    /// The priority of the `Plugins.curlOS` plugin.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    static let curlOS: Self = curl - 1
}

public extension Plugins {
    /// A plugin that logs the request in the `curl` format.
    /// - Parameters:
    ///  - priority: The priority of the plugin.
    ///  - shouldPrintBody: A flag that indicates whether the response body should be printed to the console or to the logger. The default value is `false`.
    ///
    /// - Note: Sometimes the response body can be very large, so it is better to print it to the console for debugging purposes.
    @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
    static func CurlOS(priority: PluginPriority = .curlOS,
                       logger: Logger? = nil,
                       shouldPrintBody: Bool = false) -> Plugins.Curl {
        let logger = logger ?? Logger(subsystem: Bundle.main.bundleIdentifier ?? "SmartNetwork.curlOS", category: "Network")
        return Plugins.Curl(id: Plugins.Curl.makeHash(withAdditionalHash: "OS"),
                            priority: priority) { component, text in
            let text: String? = text()
            switch component {
            case .curl:
                let new = text?.replacingOccurrences(of: "-H \"Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8\"", with: "")
                if let new {
                    logger.log(level: .info, "\(new)")
                } else {
                    logger.log(level: .error, "< can't create curl >")
                }
            case .error:
                if let text {
                    logger.log(level: .error, "error: \(text)")
                }
            case .body:
                let text = text ?? "< body is nil >"
                if shouldPrintBody {
                    print(text)
                } else {
                    logger.log(level: .info, "\(text)")
                }
            }
        }
    }
}
#endif
