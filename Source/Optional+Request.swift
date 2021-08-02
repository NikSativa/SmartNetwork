import Foundation

public extension Optional {
    func unwrap<T: Error>(_ error: T) throws -> Wrapped {
        switch self {
        case .none:
            throw error
        case .some(let t):
            return t
        }
    }

    func unwrap() throws -> Wrapped {
        try unwrap(DecodingError.brokenResponse)
    }
}
