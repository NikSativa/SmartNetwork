import Foundation

public protocol CURLConvertible {
    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    func cURLDescription(with session: SmartURLSession, request: URLRequest) -> String
}

public extension CURLConvertible {
    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    func cURLDescription(with session: SmartURLSession, request: URLRequest) -> String {
        guard let url = request.url,
              let host = url.host,
              let method = request.httpMethod else {
            return "$ curl command could not be created"
        }

        var components = [RequestSettings.curlStartsWithDollar ? "$ curl -v" : "curl -v"]

        components.append("-X \(method)")

        let configuration = session.configuration
        if let credentialStorage = configuration.urlCredentialStorage {
            let protectionSpace = URLProtectionSpace(host: host,
                                                     port: url.port ?? 0,
                                                     protocol: url.scheme,
                                                     realm: host,
                                                     authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else {
                        continue
                    }
                    components.append("-u \(user):\(password)")
                }
            }
        }

        if configuration.httpShouldSetCookies {
            if let cookieStorage = configuration.httpCookieStorage,
               let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
                let allCookies = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: ";")

                components.append("-b \"\(allCookies)\"")
            }
        }

        var headers = HeaderFields()

        if let sessionHeaders = configuration.httpAdditionalHeaders {
            for header in sessionHeaders {
                if let key = header.key as? String,
                   let value = header.value as? String,
                   key != "Cookie" {
                    headers.append(key: key, value: value)
                }
            }
        }

        if let allHTTPHeaderFields = request.allHTTPHeaderFields {
            for header in allHTTPHeaderFields where header.key != "Cookie" {
                headers[header.key] = header.value
            }
        }

        let curlDisallowedHeaders = RequestSettings.curlDisallowedHeaders
        for header in headers {
            if !curlDisallowedHeaders.contains(header.key) {
                let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
                components.append("-H \"\(header.key): \(escapedValue)\"")
            }
        }

        if let httpBodyData = request.httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

            components.append("-d \"\(escapedBody)\"")
        }

        components.append("\"\(url.absoluteString)\"")

        var curl = components.joined(separator: " \\\n\t")
        if RequestSettings.curlPrettyPrinted {
            curl += " | json_pp"
        }
        return curl
    }
}
