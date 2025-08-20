import Foundation

/// A deserializer for requests that are expected to have no response body.
///
/// `VoidContent` ignores any response payload and reports success when the transport
/// layer indicates success. It treats HTTP 204 (No Content) as success even when
/// surfaced as a `.noContent` status error in `SmartResponse.error`.
///
/// This type is stateless and thread-safe.
///
/// - SeeAlso: `SmartResponse`, `StatusCode.noContent`, `RequestDecodingError`
public struct VoidContent: Deserializable {
    /// Creates a new `VoidContent` deserializer.
    public init() {}

    /// Interprets a `SmartResponse` when no body is expected.
    ///
    /// Error precedence is as follows:
    /// 1. If `data.error` is `.noContent` (HTTP 204), return `.success(())`.
    /// 2. If `data.error` is any other non-`nil` error, return `.failure` with that error.
    /// 3. Otherwise, return `.success(())` regardless of `data.body`.
    ///
    /// - Parameters:
    ///   - data: The response to evaluate.
    ///   - parameters: Request parameters. Not used by this type.
    /// - Returns: `.success(())` when there is no error or when the error is `.noContent`; otherwise `.failure` with the error.
    ///
    /// # Example
    /// ```swift
    /// let content = VoidContent()
    /// let result = content.decode(with: response, parameters: [:])
    /// switch result {
    /// case .success:
    ///     print("no content as expected")
    /// case .failure(let error):
    ///     print("request failed:", error)
    /// }
    /// ```
    public func decode(with data: SmartResponse, parameters: Parameters) -> Result<Void, Error> {
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
