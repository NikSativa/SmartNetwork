import Foundation

public enum HTTPMethod: Equatable {
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

extension HTTPMethod {
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
