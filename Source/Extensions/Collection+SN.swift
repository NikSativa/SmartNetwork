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
    /// Returns `nil` if the collection is empty.
    var nilIfEmpty: Self? {
        return isEmpty ? nil : self
    }

    func filterNils<T>() -> [T] where Element == T? {
        #if swift(>=6.0)
        return compactMap(\.self)
        #else
        return compactMap { $0 }
        #endif
    }
}

internal extension Optional where Wrapped: Collection {
    /// Returns `nil` if the collection is empty.
    var nilIfEmpty: Self {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped.isEmpty ? nil : wrapped
        }
    }
}
