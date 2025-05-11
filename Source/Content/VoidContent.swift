import Foundation

/// A deserializer used for requests that expect no response body.
///
/// `VoidContent` returns `.success(())` on success and propagates errors if present,
/// ignoring the response body entirely. It also treats HTTP 204 (No Content) as success.
struct VoidContent: Deserializable {
    /// Interprets a `SmartResponse` for use cases where no body is expected.
    ///
    /// - Parameters:
    ///   - data: The response to evaluate.
    ///   - parameters: The request parameters (not used).
    /// - Returns: `.success(())` if the response has no error or if the error is `.noContent`; otherwise returns `.failure`.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<Void, Error> {
        if let error = data.error {
            if let error = data.error as? StatusCode, error == .noContent {
                return .success(())
            } else {
                return .failure(error)
            }
        } else {
            return .success(())
        }
    }
}
