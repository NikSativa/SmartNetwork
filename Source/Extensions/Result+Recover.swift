import Foundation

internal extension Result where Failure: Error {
    /// Returns the original result if successful, or a default value if the error is recoverable.
    ///
    /// - Parameter defaultValue: The value to use when recovering from a recoverable error.
    /// - Returns: A `.success` result containing the original or default value, or `.failure` if the error is not recoverable.
    func recoverResult(_ defaultValue: Success) -> Result<Success, Failure> {
        switch self {
        case .success(let obj):
            return .success(obj)
        case .failure(let error):
            return error.isRecoverable ? .success(defaultValue) : .failure(error)
        }
    }

    /// Returns the original result if successful, or `.success(nil)` if the error is recoverable.
    ///
    /// This method wraps the result in an optional, making it useful for cases where `nil` is an acceptable fallback.
    ///
    /// - Returns: A `.success` result containing the original value or `nil`, or `.failure` if the error is not recoverable.
    func recoverResult() -> Result<Success?, Failure> {
        switch self {
        case .success(let obj):
            return .success(obj)
        case .failure(let error):
            return error.isRecoverable ? .success(nil) : .failure(error)
        }
    }
}

/// Indicates whether the error is considered recoverable based on its type.
///
/// Currently, only decoding errors are treated as recoverable.
private extension Error {
    var isRecoverable: Bool {
        switch requestError {
        case .decoding:
            return true
        default:
            return false
        }
    }
}
