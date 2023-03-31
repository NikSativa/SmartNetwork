import Foundation

public enum RequestDecodingError: Error {
    case other(DecodingError)
    case brokenImage
    case brokenResponse
    case nilResponse
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
        }
    }
}
