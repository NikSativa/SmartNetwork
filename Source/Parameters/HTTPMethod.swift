import Foundation

public enum HTTPMethod: Equatable {
    case post
    case get
    case put
    case delete
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
        }
    }
}
