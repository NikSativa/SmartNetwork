import Foundation

/// The enum also provides a RequestErrorDescription extension to handle and provide descriptions for each case within the RequestError system.
public enum RequestDecodingError: Error {
    /// Wraps another DecodingError within it.
    case other(DecodingError)
    /// Indicates errors related to decoding an image.
    case brokenImage
    /// Indicates errors related to a broken
    case brokenResponse
    /// Indicates errors related to a nil response
    case nilResponse
    /// Indicates errors related to an empty response
    case emptyResponse
    /// Indicates errors related to a nil response by key path
    case nilResponseByKeyPath(String)
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
        case .nilResponseByKeyPath(let key):
            return "nilResponseByKeyPath(\(key))"
        }
    }
}
