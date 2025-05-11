import Foundation

/// A deserializer that converts response data into a platform-specific image.
///
/// This is useful for decoding image responses from the network into `SmartImage`
/// (e.g., `UIImage` on iOS or `NSImage` on macOS).
struct ImageContent: Deserializable {
    /// Attempts to decode image data from the response.
    ///
    /// - Parameters:
    ///   - data: The response object containing the body and any associated error.
    ///   - parameters: The request parameters (unused).
    /// - Returns: A result containing a decoded image or a decoding error.
    func decode(with data: SmartResponse, parameters: Parameters) -> Result<SmartImage, Error> {
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
