import Foundation

public extension Collection {
    func throwIfEmpty<T: Error>(_ error: T) throws -> Self {
        if isEmpty {
            throw error
        }
        return self
    }

    func throwIfEmpty() throws -> Self {
        if isEmpty {
            throw DecodingError.brokenResponse
        }
        return self
    }
}
