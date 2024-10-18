import Foundation

public extension Optional {
    /// Unwraps the optional value or throws the specified error.
    ///
    /// - Parameters:
    ///   - error: The error to throw if the optional value is nil.
    /// - Returns: The unwrapped value of the optional.
    /// - Throws: The specified error if the optional value is nil.
    func unwrap(orThrow error: Error) throws -> Wrapped {
        switch self {
        case .none:
            throw error
        case .some(let value):
            return value
        }
    }

    /// Unwraps the optional value or throws a default decoding error.
    ///
    /// - Returns: The unwrapped value of the optional.
    /// - Throws: `RequestDecodingError.brokenResponse` if the optional value is nil.
    func unwrap() throws -> Wrapped {
        try unwrap(orThrow: RequestDecodingError.brokenResponse)
    }
}
