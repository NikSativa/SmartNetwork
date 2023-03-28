import Foundation

/// Matcher for testing an *URLRequest's*
public enum HTTPStubCondition {
    /// **Path** of URL
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin** in *https://api.example.com/signin*.
    ///
    /// - Note: URL paths are usually absolute and thus starts with a '/' (which you
    ///         should include in the *path* parameter unless you're testing relative URLs)
    case isPath(String)

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

    /// Prefix of the **path**
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin** in *https://api.example.com/signin*.
    ///
    /// - Note: URL paths are usually absolute and thus starts with a '/' (which you
    ///         should include in the *path* parameter unless you're testing relative URLs)
    case pathStartsWith(String)

    /// Suffix of the **path**
    ///
    /// - Parameter path: The path to match, e.g. the path is **/signin** in *https://api.example.com/signin*.
    ///
    /// - Note: URL paths are usually absolute and thus starts with a '/' (which you
    ///         should include in the *path* parameter unless you're testing relative URLs)
    case pathEndsWith(String)

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
    @available(macOS 13.0, iOS 16.0, *)
    public static func pathMatches(_ regex: Regex<some Any>) -> Self {
        return .custom { request in
            return request.path.map { path in
                let match = path.firstMatch(of: regex)
                return match != nil
            }
        }
    }

    /// RegEx matches the **absolute atring**
    ///
    /// - Parameter regex: The Regular Expression we want the absolute string to match
    @available(macOS 13.0, iOS 16.0, *)
    public static func absoluteStringMatches(_ regex: Regex<some Any>) -> Self {
        return .custom { request in
            return request.absoluteString.map { path in
                let match = path.firstMatch(of: regex)
                return match != nil
            }
        }
    }

    public typealias TestClosure = (_ request: URLRequest) -> Bool?
    case custom(TestClosure)

    func test(_ request: URLRequest) -> Bool {
        let result: Bool?
        switch self {
        case .isPath(let string):
            result = request.url?.path == string
        case .isHost(let string):
            precondition(!string.contains("/"), "The host part of an URL never contains any slash. Only use strings like 'api.example.com' for this value, and not things like 'https://api.example.com/'")
            result = request.url?.host == string
        case .isAbsoluteURLString(let string):
            result = request.absoluteString == string
        case .isMethod(let string):
            result = request.httpMethod == string
        case .isScheme(let string):
            assert(!string.contains("://"), "The scheme part of an URL never contains '://'. Only use strings like 'https' for this value, and not things like 'https://'")
            assert(!string.contains("/"), "The scheme part of an URL never contains any slash. Only use strings like 'https' for this value, and not things like 'https://api.example.com/'")
            result = request.url?.scheme == string
        case .pathStartsWith(let string):
            result = request.path?.hasPrefix(string)
        case .pathEndsWith(let string):
            result = request.path?.hasSuffix(string)
        case .pathNSMatches(let regex):
            result = request.path.map { path in
                let range = NSRange(location: 0, length: path.utf16.count)
                let matches = regex.firstMatch(in: path, options: [], range: range)
                return matches != nil
            }
        case .absoluteStringNSMatches(let regex):
            result = request.absoluteString.map { path in
                let range = NSRange(location: 0, length: path.utf16.count)
                let matches = regex.firstMatch(in: path, options: [], range: range)
                return matches != nil
            }
        case .custom(let closure):
            result = closure(request)
        }
        return result ?? false
    }
}

private extension URLRequest {
    var absoluteString: String? {
        return url?.absoluteString
    }

    var path: String? {
        return url?.path
    }
}
