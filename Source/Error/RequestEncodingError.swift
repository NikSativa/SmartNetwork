import Foundation

/// The enum also provides a RequestErrorDescription extension to handle and provide descriptions for each case within the RequestError system.
public enum RequestEncodingError: Error {
    /// Wraps another EncodingError within it.
    case other(EncodingError)
    /// Indicates an issue with invalid parameters for encoding.
    case invalidParameters
    /// Represents errors related to a broken or malformed URL.
    case brokenURL
    /// Indicates errors related to a broken address in the request.
    case brokenAddress
    /// Indicates errors related to a broken host in the request.
    case brokenHost
    /// Indicates errors related to encoding an image.
    case cantEncodeImage
    /// Indicates errors related to invalid JSON.
    case invalidJSON
}

// MARK: - RequestErrorDescription

extension RequestEncodingError: RequestErrorDescription {
    public var subname: String {
        switch self {
        case .other(let encodingError):
            let description = (encodingError as NSError).description
            return ".other(\(description))"
        case .invalidParameters:
            return "invalidParameters"
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
