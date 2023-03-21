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
        try unwrap(orThrow: DecodingError.brokenResponse)
    }

    func unwrapOrEmpty<Element>() -> [Element] where Wrapped == [Element] {
        return self ?? []
    }

    func unwrapOrEmpty<Key, Value>() -> [Key: Value] where Wrapped == [Key: Value] {
        return self ?? [:]
    }
}
