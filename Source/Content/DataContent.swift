import Foundation

/// A deserializer that extracts the raw `Data` payload from a `SmartResponse`.
///
/// Use `DataContent` when you expect unprocessed binary data (for example, images,
/// files, or any opaque blob returned by the server). If the response contains a
/// non-`nil` `error`, the decode result is `.failure(error)`. If the response has
/// no body, the result is `.failure(RequestDecodingError.nilResponse)`.
///
/// This type is stateless and thread‑safe.
///
/// - SeeAlso: `Deserializable`, `SmartResponse`, `RequestDecodingError`
public struct DataContent: Deserializable {
    /// Creates a new `DataContent` deserializer.
    public init() {}

    /// Attempts to extract the raw body `Data` from a `SmartResponse`.
    ///
    /// Error precedence is as follows:
    /// 1. If `data.error` is non-`nil`, return `.failure` with that error.
    /// 2. If `data.body` is `nil`, return `.failure(RequestDecodingError.nilResponse)`.
    /// 3. Otherwise, return `.success(Data)` with the body bytes.
    ///
    /// - Parameters:
    ///   - data: The response to decode, containing `body` and `error`.
    ///   - parameters: Request parameters. Not used by this type.
    /// - Returns: `.success` with the response body as `Data`, or `.failure` describing why the body is unavailable.
    ///
    /// # Example
    /// ```swift
    /// let deserializer = DataContent()
    /// let result = deserializer.decode(with: response, parameters: [:])
    /// switch result {
    /// case .success(let payload):
    ///     print("bytes:", payload.count)
    /// case .failure(let error):
    ///     print("decode failed:", error)
    /// }
    /// ```
    public func decode(with data: SmartResponse, parameters: Parameters) -> Result<Data, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            return .success(data)
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
