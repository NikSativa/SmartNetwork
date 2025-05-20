import Foundation

/// Provides an interface for converting a `URLRequest` into a `cURL` command string.
///
/// Types conforming to `CURLConvertible` can produce a `cURL`-formatted command useful for debugging, logging,
/// or reproducing network requests outside the app. Extensions also provide convenience methods for default behavior.
public protocol CURLConvertible: SmartSendable {
    /// Generates a `cURL` command string that represents the given `URLRequest`.
    ///
    /// This method assembles a full cURL command based on the request and session parameters,
    /// including method, headers, cookies, credentials, and body content.
    ///
    /// - Parameters:
    ///   - session: The `SmartURLSession` whose configuration provides cookie and credential storage.
    ///   - request: The `URLRequest` to be converted to a cURL command.
    ///   - prettyPrinted: If `true`, appends `| json_pp` to the command for pretty-printing JSON output.
    /// - Returns: A `String` representing the cURL equivalent of the request, or an error message if the request is invalid.
    func cURLDescription(with session: SmartURLSession, request: URLRequest, prettyPrinted: Bool) -> String
}

public extension CURLConvertible {
    /// Generates a `cURL` command string for the given `URLRequest` without pretty-printing.
    ///
    /// This convenience method calls `cURLDescription(with:request:prettyPrinted:)` with `prettyPrinted` set to `false`
    /// for performance optimization.
    ///
    /// - Parameters:
    ///   - session: The `SmartURLSession` instance providing session configuration, including headers and credentials.
    ///   - request: The `URLRequest` to convert to a cURL command string.
    /// - Returns: A `String` representing the equivalent `cURL` command for the request.
    func cURLDescription(with session: SmartURLSession, request: URLRequest) -> String {
        return cURLDescription(with: session, request: request, prettyPrinted: false)
    }
}

public extension CURLConvertible {
    /// Constructs a shell-compatible `cURL` command that simulates the given `URLRequest` using the specified session context.
    ///
    /// This method generates a shell-compatible `cURL` command that reflects the configuration and contents of the provided
    /// `SmartURLSession` and `URLRequest`. It includes the HTTP method, headers (excluding disallowed and cookie headers),
    /// credentials (if present in the session's credential storage), cookies, and the body data.
    ///
    /// - Parameters:
    ///   - session: The `SmartURLSession` providing cookie and credential context for the request.
    ///   - request: The `URLRequest` to transform into an equivalent `cURL` command.
    ///   - prettyPrinted: If `true`, appends `| json_pp` to the end of the command for formatting JSON output.
    /// - Returns: A string representing the full `cURL` command, or a placeholder message if generation fails.
    func cURLDescription(with session: SmartURLSession, request: URLRequest, prettyPrinted: Bool) -> String {
        guard let url = request.url,
              let host = url.host,
              let method = request.httpMethod else {
            return "$ curl command could not be created"
        }

        // Determine whether JSON pretty-printing is enabled, either from the parameter or global settings.
        let prettyPrinted = prettyPrinted || SmartNetworkSettings.curlPrettyPrinted

        var components = [SmartNetworkSettings.curlStartsWithDollar ? "$ curl -v" : "curl -v"]

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

        // `Content-Length` must be removed because `httpBodyData` is modified during cURL formatting
        let curlDisallowedHeaders: Set<String> = Set(SmartNetworkSettings.curlDisallowedHeaders + ["Content-Length"])
        let headerItems = prettyPrinted ? headers.sorted(by: { $0.key < $1.key }) : headers.rawValues
        for header in headerItems {
            if !curlDisallowedHeaders.contains(header.key) {
                components.append("-H '\(header.key): \(header.value)'")
            }
        }

        if let httpBodyData = request.httpBody {
            let httpBody: String
            if prettyPrinted,
               let json = try? JSONSerialization.jsonObject(with: httpBodyData),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) {
                httpBody = .init(decoding: prettyData, as: UTF8.self)
            } else {
                httpBody = .init(decoding: httpBodyData, as: UTF8.self)
            }

            components.append("-d '\(httpBody)'")
        }

        components.append("'\(url.absoluteString)'")

        var curl = components.joined(separator: " \\\n\t")
        if SmartNetworkSettings.curlAddJSON_PP {
            curl += " | json_pp"
        }
        return curl
    }
}
