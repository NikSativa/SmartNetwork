import Foundation

public extension Plugins {
    final class Curl: Plugin {
        public typealias Logging = (_ component: Component, _ text: () -> String?) -> Void
        public enum Component {
            case curl
            case error
            case body
        }

        private let logger: Logging

        public init(logger: @escaping Logging) {
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

            let headers: HeaderFields = request.allHTTPHeaderFields ?? [:]
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
