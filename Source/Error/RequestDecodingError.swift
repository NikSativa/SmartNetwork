import Foundation

/// Represents decoding-related errors that occur while interpreting a network response.
///
/// `RequestDecodingError` defines specific failure cases such as missing or malformed response content,
/// image decoding issues, or broken key paths. It integrates with `RequestErrorDescription` to support
/// consistent and informative logging.
public enum RequestDecodingError: Error {
    /// Wraps a general `DecodingError` returned by Swift's decoding infrastructure.
    case other(DecodingError)
    /// Indicates that image data could not be decoded properly.
    case brokenImage
    /// Indicates a structurally invalid or corrupted response.
    case brokenResponse
    /// Indicates that the response was unexpectedly `nil`.
    case nilResponse
    /// Indicates that the response body was unexpectedly empty.
    case emptyResponse
    /// Indicates that decoding failed due to an invalid or unreachable key path.
    ///
    /// - Parameter key: The key path that caused the decoding failure.
    case brokenKeyPath(String)
}

// MARK: - RequestErrorDescription

extension RequestDecodingError: RequestErrorDescription {
    public var subname: String {
        switch self {
        case .other(let encodingError):
            let description = (encodingError as NSError).description
            return ".other(\(description))"
        case .brokenImage:
            return "brokenImage"
        case .brokenResponse:
            return "brokenResponse"
        case .nilResponse:
            return "nilResponse"
        case .emptyResponse:
            return "emptyResponse"
        case .brokenKeyPath(let key):
            return "brokenKeyPath(\(key))"
        }
    }
}
