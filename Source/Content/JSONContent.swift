import Foundation

/// A deserializer that interprets a `SmartResponse` body as a JSON value using `JSONSerialization`.
///
/// `JSONContent` is suitable for endpoints that return dynamic or loosely-typed JSON where
/// a concrete `Decodable` model is not available. It produces Foundation-compatible values
/// (`Array`, `Dictionary`, `String`, `NSNumber`, `NSNull`).
///
/// If `data.error` is non-`nil`, that error is returned. If the body is `nil` or empty,
/// the corresponding `RequestDecodingError` is returned. On JSON parsing failure, the
/// thrown `JSONSerialization` error is returned.
///
/// This type is stateless and thread-safe.
///
/// - SeeAlso: `DecodableContent`, `DataContent`, `SmartResponse`, `RequestDecodingError`
public struct JSONContent: Deserializable {
    /// Creates a new `JSONContent` deserializer.
    public init() {}
    
    /// Decodes the response body into a Foundation JSON value using `JSONSerialization`.
    ///
    /// Error precedence is as follows:
    /// 1. If `data.error` is non-`nil`, return `.failure` with that error.
    /// 2. If `data.body` is `nil`, return `.failure(RequestDecodingError.nilResponse)`.
    /// 3. If `data.body` is empty, return `.failure(RequestDecodingError.emptyResponse)`.
    /// 4. If JSON parsing throws, return `.failure` with the thrown error.
    ///
    /// - Parameters:
    ///   - data: The `SmartResponse` containing the raw body and any associated error.
    ///   - parameters: Request parameters. Not used by this type.
    /// - Returns: `.success(Any)` with a Foundation JSON value or `.failure` describing why decoding was not possible.
    ///
    /// # Example
    /// ```swift
    /// let content = JSONContent()
    /// let result = content.decode(with: response, parameters: [:])
    /// switch result {
    /// case .success(let json):
    ///     if let dict = json as? [String: Any] { print(dict) }
    /// case .failure(let error):
    ///     print("json decode failed:", error)
    /// }
    /// ```
    public func decode(with data: SmartResponse, parameters: Parameters) -> Result<Any, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }
            
            do {
                return try .success(JSONSerialization.jsonObject(with: data))
            } catch {
                return .failure(error)
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
