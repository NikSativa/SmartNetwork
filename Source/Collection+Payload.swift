import Foundation

public extension Collection {
    func throwIfEmpty(_ error: some Error) throws -> Self {
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
