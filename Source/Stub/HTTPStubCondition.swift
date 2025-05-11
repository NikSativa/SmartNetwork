import Foundation
import Threading

/// A matcher used to evaluate `URLRequestRepresentation` instances against specific URL or HTTP attributes.
public enum HTTPStubCondition {
    /// Matches requests with a URL equal to the given `Address`.
    ///
    /// - Parameter address: The full `Address` to match.
    case isAddress(Address)

    /// Matches requests whose path exactly equals the provided path components.
    ///
    /// - Parameter path: The expected path components (e.g., `["signin"]` for `/signin`).
    case isPath([String])

    /// Creates a matcher for requests whose path exactly equals the given string.
    ///
    /// - Parameter path: A string path (e.g., `"/signin"`).
    public static func isPath(_ path: String) -> Self {
        return .isPath(path.toPathComponents)
    }

    /// Matches requests whose path begins with the given components.
    ///
    /// - Parameter path: Path components to match.
    case pathStartsWith([String])

    /// Matches requests whose path begins with the given components.
    ///
    /// - Parameter path: Path components to match.
    public static func pathStartsWith(_ path: String) -> Self {
        return .pathStartsWith(path.toPathComponents)
    }

    /// Matches requests whose path ends with the given components.
    ///
    /// - Parameter path: Path components to match.
    case pathEndsWith([String])

    /// Matches requests whose path ends with the given components.
    ///
    /// - Parameter path: Path components to match.
    public static func pathEndsWith(_ path: String) -> Self {
        return .pathEndsWith(path.toPathComponents)
    }

    /// Matches requests whose path contains the given components.
    ///
    /// - Parameter path: Path components to match.
    /// - Parameter keepingOrder: If `true`, the components must appear in order.
    case pathContains([String], keepingOrder: Bool)

    /// Matches requests whose path contains the given components.
    ///
    /// - Parameter path: Path components to match.
    /// - Parameter keepingOrder: If `true`, the components must appear in order.
    public static func pathContains(_ path: String, keepingOrder: Bool = true) -> Self {
        return .pathContains(path.toPathComponents, keepingOrder: keepingOrder)
    }

    /// Matches requests whose host exactly equals the given string.
    ///
    /// - Parameter host: Host string (e.g., `"api.example.com"`).
    case isHost(String)

    /// Matches requests whose full URL string equals the given string.
    ///
    /// - Parameter url: The absolute URL string.
    case isAbsoluteURLString(String)

    /// Matches requests with a specific HTTP method.
    ///
    /// - Parameter method: HTTP method string (e.g., `"GET"` or `"POST"`).
    case isMethod(String)

    /// Matches requests with a specific URL scheme.
    ///
    /// - Parameter scheme: Scheme string (e.g., `"https"`).
    case isScheme(String)

    /// Matches requests whose path matches the given regular expression.
    ///
    /// - Parameter regex: An `NSRegularExpression` used to match the respective property.
    ///
    /// - Note: URL paths are usually absolute and thus start with a '/'
    case pathNSMatches(NSRegularExpression)

    /// Matches requests whose absolute string matches the given regular expression.
    ///
    /// - Parameter regex: An `NSRegularExpression` used to match the respective property.
    case absoluteStringNSMatches(NSRegularExpression)

    /// Matches the request path against a Swift regex.
    ///
    /// - Parameter regex: A Swift `Regex` for matching.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public static func pathMatches(_ regex: Regex<some Any>) -> Self {
        let regex = USendable(regex)
        return .custom { request in
            guard let path = request.url?.path else {
                return false
            }

            let match = path.firstMatch(of: regex.value)
            return match != nil
        }
    }

    /// Matches the full URL string against a Swift regex.
    ///
    /// - Parameter regex: A Swift `Regex` for matching.
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public static func absoluteStringMatches(_ regex: Regex<some Any>) -> Self {
        let regex = USendable(regex)
        return .custom { request in
            return request.absoluteString.map { path in
                let match = path.firstMatch(of: regex.value)
                return match != nil
            } ?? false
        }
    }

    /// Applies a custom matching closure to evaluate the request.
    case custom(TestClosure)

    func test(_ request: URLRequestRepresentation) -> Bool {
        switch self {
        case .isAddress(let address):
            let original = request.url.flatMap {
                return Address($0)
            }

            guard let lhs = try? original?.url() else {
                return false
            }

            guard let rhs = try? address.url() else {
                return false
            }

            return lhs == rhs
        case .isPath(let string):
            return request.path == string
        case .pathStartsWith(let string):
            return Array(request.path.prefix(string.count)) == string
        case .pathEndsWith(let string):
            return Array(request.path.suffix(string.count)) == string
        case .pathContains(let pathComponents, let keepingOrder):
            let path = request.path
            var pathComponents = pathComponents

            if keepingOrder {
                for component in path {
                    if component == pathComponents.first {
                        pathComponents.removeFirst()
                        if pathComponents.isEmpty {
                            return true
                        }
                    }
                }
            } else {
                for component in path {
                    if let index = pathComponents.firstIndex(of: component) {
                        pathComponents.remove(at: index)
                        if pathComponents.isEmpty {
                            return true
                        }
                    }
                }
            }
            return false
        case .isHost(let string):
            precondition(!string.contains("/"), "The host part of an URL never contains any slash. Only use strings like 'api.example.com' for this value, and not things like 'https://api.example.com/'")
            return request.url?.host == string
        case .isAbsoluteURLString(let string):
            return request.absoluteString == string
        case .isMethod(let string):
            return request.httpMethod == string
        case .isScheme(let string):
            assert(!string.contains("://"), "The scheme part of an URL never contains '://'. Only use strings like 'https' for this value, and not things like 'https://'")
            assert(!string.contains("/"), "The scheme part of an URL never contains any slash. Only use strings like 'https' for this value, and not things like 'https://api.example.com/'")
            return request.url?.scheme == string
        case .pathNSMatches(let regex):
            guard let path = request.url?.path else {
                return false
            }
            let range = NSRange(location: 0, length: path.utf16.count)
            let matches = regex.firstMatch(in: path, options: [], range: range)
            return matches != nil
        case .absoluteStringNSMatches(let regex):
            guard let absoluteString = request.absoluteString else {
                return false
            }
            let range = NSRange(location: 0, length: absoluteString.utf16.count)
            let matches = regex.firstMatch(in: absoluteString, options: [], range: range)
            return matches != nil
        case .custom(let closure):
            return closure(request)
        }
    }
}

private extension URLRequestRepresentation {
    var absoluteString: String? {
        return url?.absoluteString
    }

    var httpMethod: String? {
        return sdk.httpMethod
    }

    var path: [String] {
        guard let path = url?.path else {
            return []
        }
        return path.toPathComponents
    }
}

private extension String {
    var toPathComponents: [String] {
        return components(separatedBy: "/").filter { !$0.isEmpty }
    }
}

#if swift(>=6.0)
extension HTTPStubCondition: Sendable {
    /// A closure used to evaluate whether a given `URLRequestRepresentation` matches custom conditions.
    ///
    /// Return `true` to indicate a match, or `false` otherwise.
    public typealias TestClosure = @Sendable (_ request: URLRequestRepresentation) -> Bool
}
#else
public extension HTTPStubCondition {
    /// A closure used to evaluate whether a given `URLRequestRepresentation` matches custom conditions.
    ///
    /// Return `true` to indicate a match, or `false` otherwise.
    typealias TestClosure = (_ request: URLRequestRepresentation) -> Bool
}
#endif
