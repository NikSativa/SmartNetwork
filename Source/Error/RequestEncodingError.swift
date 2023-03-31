import Foundation

public enum RequestEncodingError: Error {
    case other(EncodingError)
    case invalidParameters
    case brokenURL
    case brokenAddress
    case brokenHost
    case cantEncodeImage
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
