import Foundation

/// Represents common encoding errors encountered during request construction.
///
/// `RequestEncodingError` categorizes failures that occur while encoding URLs, addresses,
/// hosts, images, or JSON for a request. These errors are integrated into the `RequestError` system
/// via the `RequestErrorDescription` protocol.
public enum RequestEncodingError: Error {
    /// Wraps a generic `EncodingError`, preserving the underlying cause.
    case other(EncodingError)
    /// Indicates a malformed or invalid URL that failed during encoding.
    case brokenURL
    /// Indicates that the request address could not be correctly encoded.
    case brokenAddress
    /// Indicates failure to encode the host component of the URL.
    case brokenHost
    /// Indicates a failure to encode an image as part of the request body.
    case cantEncodeImage
    /// Indicates a failure to produce valid JSON during encoding.
    case invalidJSON
}

// MARK: - RequestErrorDescription

extension RequestEncodingError: RequestErrorDescription {
    /// A short descriptive identifier for logging and diagnostics.
    ///
    /// Used by the `RequestErrorDescription` protocol to generate meaningful output for each error case.
    public var subname: String {
        switch self {
        case .other(let encodingError):
            let description = (encodingError as NSError).description
            return ".other(\(description))"

        case .brokenURL:
            return "brokenURL"

        case .brokenAddress:
            return "brokenAddress"

        case .brokenHost:
            return "brokenHost"

        case .cantEncodeImage:
            return "cantEncodeImage"

        case .invalidJSON:
            return "invalidJSON"
        }
    }
}
