import Foundation

/// Represents a URL scheme component such as `http`, `https`, or a custom value.
///
/// This enum supports standard schemes as well as custom or empty values through the `.other` case.
public enum Scheme: Hashable, SmartSendable {
    case http
    case https

    /// A custom or empty scheme value.
    ///
    /// Use this case to represent non-standard schemes or intentionally empty scheme components.
    case other(String)
}

// MARK: - ExpressibleByStringLiteral

/// Allows string literals to initialize `Scheme` values using the `.other` case.
extension Scheme: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .other(value)
    }
}

internal extension Scheme {
    /// Converts the `Scheme` to its string representation.
    ///
    /// - Returns: `"http"`, `"https"`, or a custom/non-empty string. Returns `nil` if the scheme is empty.
    func toString() -> String? {
        switch self {
        case .http:
            return "http"
        case .https:
            return "https"
        case .other(let string):
            // scheme can be represented as empty string
            return string.nilIfEmpty
        }
    }
}
