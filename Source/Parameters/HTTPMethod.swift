import Foundation

/// Represents an HTTP method used to define the type of network request.
///
/// Used in `Parameters` to indicate the desired request action, such as `GET`, `POST`, or a custom method via `.other`.
public enum HTTPMethod: Hashable, SmartSendable {
    case get
    case head
    case post
    case put
    case delete
    case connect
    case options
    case trace
    case patch
    /// A custom HTTP method not covered by standard cases.
    case other(String)
}

// MARK: - ExpressibleByStringLiteral

extension HTTPMethod: ExpressibleByStringLiteral {
    /// Allows initialization of `HTTPMethod` using string literals.
    ///
    /// Example:
    /// ```swift
    /// let method: HTTPMethod = "CUSTOM"
    /// ```
    public init(stringLiteral value: String) {
        self = .other(value)
    }
}

internal extension HTTPMethod {
    /// Converts the `HTTPMethod` to its uppercase string representation.
    ///
    /// - Returns: The corresponding HTTP method string (e.g., `"GET"`, `"POST"`).
    func toString() -> String {
        switch self {
        case .get:
            return "GET"
        case .head:
            return "HEAD"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        case .connect:
            return "CONNECT"
        case .options:
            return "OPTIONS"
        case .trace:
            return "TRACE"
        case .patch:
            return "PATCH"
        case .other(let str):
            return str
        }
    }
}
