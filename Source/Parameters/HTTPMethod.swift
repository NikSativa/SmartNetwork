import Foundation

public enum HTTPMethod: Equatable {
    case post
    case get
    case put
    case delete
    case other(String)
}

extension HTTPMethod {
    func toString() -> String {
        switch self {
        case .post:
            return "POST"
        case .get:
            return "GET"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        case .other(let str):
            return str
        }
    }
}
