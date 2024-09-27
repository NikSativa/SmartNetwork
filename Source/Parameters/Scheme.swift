import Foundation

public enum Scheme: Hashable {
    case http
    case https

    /// **NOTE** scheme can be represented as empty string
    case other(String)
}

// MARK: - ExpressibleByStringLiteral

extension Scheme: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .other(value)
    }
}

internal extension Scheme {
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

#if swift(>=6.0)
extension Scheme: Sendable {}
#endif
