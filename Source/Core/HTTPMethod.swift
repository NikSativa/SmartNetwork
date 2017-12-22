import Foundation

public enum HTTPMethod {
    case post(Body)
    case get
    case put
    case delete

    public init<T: Encodable>(post object: T) {
        self = .post(Body(with: object))
    }
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
