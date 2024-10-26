import Foundation

public extension Collection {
    /// Throws the specified error if the collection is empty.
    func throwIfEmpty(_ error: some Error) throws -> Self {
        if isEmpty {
            throw error
        }
        return self
    }

    /// Throws a default decoding error if the collection is empty.
    func throwIfEmpty() throws -> Self {
        return try throwIfEmpty(RequestDecodingError.brokenResponse)
    }
}

internal extension Collection {
    var nilIfEmpty: Self? {
        return isEmpty ? nil : self
    }
}

internal extension Optional where Wrapped: Collection {
    var nilIfEmpty: Self {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped.isEmpty ? nil : wrapped
        }
    }
}
