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
            case phase
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
        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo) {
            logger(.phase) {
                "willSend"
            }

            logger(.curl) {
                let curl = makeCurl(for: request.sdk)
                return curl
            }
        }

        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}

        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {
            logger(.phase) {
                "didFinish"
            }

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
