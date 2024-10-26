import Foundation

/// HTTP method types. It is used in `Parameters` to specify the HTTP method.
public enum HTTPMethod: Hashable {
    case get
    case head
    case post
    case put
    case delete
    case connect
    case options
    case trace
    case patch
    case other(String)
}

#if swift(>=6.0)
extension HTTPMethod: Sendable {}
#endif

// MARK: - ExpressibleByStringLiteral

extension HTTPMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .other(value)
    }
}

internal extension HTTPMethod {
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
