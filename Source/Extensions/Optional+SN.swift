import Foundation

public extension Optional {
    /// Attempts to unwrap the optional value or throws a custom error if it is `nil`.
    ///
    /// - Parameter error: The error to throw when the value is `nil`.
    /// - Returns: The unwrapped value.
    /// - Throws: The provided error if the optional is `nil`.
    func unwrap(orThrow error: Error) throws -> Wrapped {
        switch self {
        case .none:
            throw error
        case .some(let value):
            return value
        }
    }

    /// Attempts to unwrap the optional value or throws a default decoding error if it is `nil`.
    ///
    /// - Returns: The unwrapped value.
    /// - Throws: `RequestDecodingError.brokenResponse` if the optional is `nil`.
    func unwrap() throws -> Wrapped {
        try unwrap(orThrow: RequestDecodingError.brokenResponse)
    }
}
