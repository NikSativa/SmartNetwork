import Foundation

public extension Optional {
    func unwrap(orThrow error: some Error) throws -> Wrapped {
        switch self {
        case .none:
            throw error
        case .some(let t):
            return t
        }
    }

    func unwrap() throws -> Wrapped {
        try unwrap(orThrow: RequestDecodingError.brokenResponse)
    }
}
