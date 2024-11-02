import Foundation

/// RequestError is an essential component for handling and
/// categorizing errors that may arise during network requests within the system.
public indirect enum RequestError: Error {
    /// A generic error not specified further.
    /// Only for your purposes. StartNetwork does't throw this error.
    case generic
    /// Wraps another error within it.
    case other(Error)
    /// Represents errors related to network connection issues, using URLError
    case connection(URLError)
    /// Indicates errors that occur during request encoding, using RequestEncodingError
    case encoding(RequestEncodingError)
    /// Indicates errors that occur during response decoding, using RequestDecodingError
    case decoding(RequestDecodingError)
    /// Represents errors related to HTTP status codes, using StatusCode
    case statusCode(StatusCode)

    /// Initializer that can convert a general Swift.Error to a specific RequestError case based on its type
    public init(_ error: Swift.Error) {
        switch error {
        case RequestError.other(let newError):
            self = .init(newError)
        case let error as Self:
            self = error
        case let error as URLError:
            self = .connection(error)
        case let error as RequestEncodingError:
            self = .encoding(error)
        case let error as EncodingError:
            self = .encoding(.other(error))
        case let error as RequestDecodingError:
            self = .decoding(error)
        case let error as DecodingError:
            self = .decoding(.other(error))
        case let error as StatusCode:
            self = .statusCode(error)
        default:
            self = .other(error)
        }
    }
}

public extension Error {
    var requestError: RequestError {
        return .init(self)
    }
}

// MARK: - RequestError + RequestErrorDescription

extension RequestError: RequestErrorDescription {
    public var subname: String {
        switch self {
        case .generic:
            return "generic"
        case .other(let error):
            let description: String
            if let subname = (error as? RequestErrorDescription)?.subname {
                description = subname
            } else {
                description = (error as NSError).description
            }
            return "other(\(description))"
        case .connection(let error):
            return "connection(URLError \(error.code.rawValue))"
        case .encoding(let error):
            return "encoding(.\(error.subname))"
        case .decoding(let error):
            return "decoding(.\(error.subname))"
        case .statusCode(let error):
            return "statusCode(.\(error.subname))"
        }
    }
}
