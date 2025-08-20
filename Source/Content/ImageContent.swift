import Foundation

/// A deserializer that converts a `SmartResponse` body into a platform-specific image (`SmartImage`).
///
/// Use `ImageContent` for endpoints that return raw image bytes (PNG/JPEG/HEIF/WebP, etc.).
/// The type attempts to create a `PlatformImage` from the raw bytes and expose its SDK image via `SmartImage`.
/// If `data.error` is non-`nil`, that error is returned. If the body is `nil` or empty, a
/// corresponding `RequestDecodingError` is returned. If image creation fails, `.brokenImage` is returned.
///
/// This type is stateless and thread‑safe.
///
/// - SeeAlso: `SmartImage`, `PlatformImage`, `RequestDecodingError`, `DataContent`
public struct ImageContent: Deserializable {
    /// Creates a new `ImageContent` deserializer.
    public init() {}

    /// Attempts to decode an image from the `SmartResponse` body.
    ///
    /// Error precedence is as follows:
    /// 1. If `data.error` is non‑`nil`, return `.failure` with that error.
    /// 2. If `data.body` is `nil`, return `.failure(RequestDecodingError.nilResponse)`.
    /// 3. If `data.body` is empty, return `.failure(RequestDecodingError.emptyResponse)`.
    /// 4. If image construction fails, return `.failure(RequestDecodingError.brokenImage)`.
    ///
    /// - Parameters:
    ///   - data: The response object containing the raw body and any associated error.
    ///   - parameters: Request parameters. Not used by this type.
    /// - Returns: `.success(SmartImage)` if decoding succeeds, otherwise `.failure` with the reason.
    ///
    /// # Example
    /// ```swift
    /// let content = ImageContent()
    /// let result = content.decode(with: response, parameters: [:])
    /// switch result {
    /// case .success(let image):
    ///     // use image
    ///     _ = image
    /// case .failure(let error):
    ///     print("image decode failed:", error)
    /// }
    /// ```
    public func decode(with data: SmartResponse, parameters: Parameters) -> Result<SmartImage, Error> {
        if let error = data.error {
            return .failure(error)
        } else if let data = data.body {
            if data.isEmpty {
                return .failure(RequestDecodingError.emptyResponse)
            }

            if let image = PlatformImage(data: data)?.sdk {
                return .success(image)
            } else {
                return .failure(RequestDecodingError.brokenImage)
            }
        } else {
            return .failure(RequestDecodingError.nilResponse)
        }
    }
}
