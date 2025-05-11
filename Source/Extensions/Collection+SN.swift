import Foundation

public extension Collection {
    /// Returns the collection or throws the specified error if it is empty.
    ///
    /// - Parameter error: The error to throw when the collection is empty.
    /// - Returns: The collection itself if not empty.
    /// - Throws: The provided error if the collection is empty.
    func throwIfEmpty(_ error: some Error) throws -> Self {
        if isEmpty {
            throw error
        }
        return self
    }

    /// Returns the collection or throws a default decoding error if it is empty.
    ///
    /// - Returns: The collection itself if not empty.
    /// - Throws: `RequestDecodingError.brokenResponse` if the collection is empty.
    func throwIfEmpty() throws -> Self {
        return try throwIfEmpty(RequestDecodingError.brokenResponse)
    }
}

internal extension Collection {
    /// Returns `nil` if the collection is empty; otherwise returns the collection.
    var nilIfEmpty: Self? {
        return isEmpty ? nil : self
    }

    /// Filters out `nil` elements from a collection of optionals.
    ///
    /// - Returns: An array of non-nil elements.
    func filterNils<T>() -> [T] where Element == T? {
        #if swift(>=6.0)
        return compactMap(\.self)
        #else
        return compactMap { $0 }
        #endif
    }
}

internal extension Optional where Wrapped: Collection {
    /// Returns `nil` if the optional collection is `nil` or empty; otherwise returns the collection.
    var nilIfEmpty: Self {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            return wrapped.isEmpty ? nil : wrapped
        }
    }
}
