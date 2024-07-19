import Foundation

/// Matcher for testing an *URLRequest's*
public enum HTTPStubCondition {
    /// **Addres** of URL
    ///
    /// - Parameter address: The 'Address' to match
    case isAddress(Address)

    /// **Path** of URL
    ///
    /// - Parameter path: The path to match, e.g. the path is **[signin]** in *https://api.example.com/signin*.
    case isPath([String])

    /// **Path** of URL
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin/** or **/signin** or **signin** in *https://api.example.com/signin*.
    public static func isPath(_ path: String) -> Self {
        return .isPath(path.toPathComponents)
    }

    /// Prefix of the **path**
    ///
    /// - Parameter path: The path to match, e.g. the path is **[signin]** in *https://api.example.com/signin*.
    case pathStartsWith([String])

    /// Prefix of the **path**
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin/** or **/signin** or **signin** in *https://api.example.com/signin*.
    public static func pathStartsWith(_ path: String) -> Self {
        return .pathStartsWith(path.toPathComponents)
    }

    /// Suffix of the **path**
    ///
    /// - Parameter path: The path to match, e.g. the path is **[signin]** in *https://api.example.com/signin*.
    case pathEndsWith([String])

    /// Suffix of the **path**
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin/** or **/signin** or **signin** in *https://api.example.com/signin*.
    public static func pathEndsWith(_ path: String) -> Self {
        return .pathEndsWith(path.toPathComponents)
    }

    /// Partially **Path** of URL
    ///
    /// - Parameter path: The path to match, e.g. the path is **[signin]** in *https://api.example.com/signin*.
    case pathContains([String], keepingOrder: Bool)

    /// Partially **Path** of URL
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin/** or **/signin** or **signin** in *https://api.example.com/signin*.
    public static func pathContains(_ path: String, keepingOrder: Bool = true) -> Self {
        return .pathContains(path.toPathComponents, keepingOrder: keepingOrder)
    }

    /// **Host** of URL
    ///
    /// - Parameter host: The host to match, e.g. the host part is **api.example.com** in *https://api.example.com/signin*.
    case isHost(String)

    /// Absolute URL string
    ///
    /// - Parameter url: The absolute url string to match, e.g. the absolute url string is https://api.example.com/signin?user=foo&password=123#anchor
    case isAbsoluteURLString(String)

    /// HTTPMethod of URLRequest
    ///
    /// - Parameter method: The HTTPMethod to match, e.g. *GET* or *POST*
    case isMethod(String)

    /// **Scheme** of URL
    ///
    /// - Parameter scheme: The scheme to match, e.g. the scheme part is **https** in https://api.example.com/signin
    case isScheme(String)

    /// RegEx matches the **path**
    ///
    /// - Parameter regex: The Regular Expression we want the path to match
    ///
    /// - Note: URL paths are usually absolute and thus starts with a '/'
    case pathNSMatches(NSRegularExpression)

    /// RegEx matches the **absolute atring**
    ///
    /// - Parameter regex: The Regular Expression we want the absolute string to match
    case absoluteStringNSMatches(NSRegularExpression)

    /// RegEx matches the **path**
    ///
    /// - Parameter regex: The Regular Expression we want the path to match
    ///
    /// - Note: URL paths are usually absolute and thus starts with a '/'
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public static func pathMatches(_ regex: Regex<some Any>) -> Self {
        return .custom { request in
            guard let path = request.url?.path else {
                return false
            }

            let match = path.firstMatch(of: regex)
            return match != nil
        }
    }

    /// RegEx matches the **absolute atring**
    ///
    /// - Parameter regex: The Regular Expression we want the absolute string to match
    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    public static func absoluteStringMatches(_ regex: Regex<some Any>) -> Self {
        return .custom { request in
            return request.absoluteString.map { path in
                let match = path.firstMatch(of: regex)
                return match != nil
            } ?? false
        }
    }

    public typealias TestClosure = (_ request: URLRequestRepresentation) -> Bool
    case custom(TestClosure)

    func test(_ request: URLRequestRepresentation) -> Bool {
        switch self {
        case .isAddress(let address):
            let original = request.url.flatMap {
                return try? Address(url: $0)
            }
            return original == address
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
