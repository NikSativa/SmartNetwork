import Foundation

/// A unified error type representing common failures during network operations.
///
/// `RequestError` standardizes various failure cases such as encoding, decoding,
/// status code mismatches, and low-level connection issues. It helps streamline
/// error inspection and categorization within the SmartNetwork system.
public indirect enum RequestError: Error {
    /// A generic fallback error not used internally by SmartNetwork.
    /// Intended for client-defined or testing use only.
    case generic
    /// Wraps any external error that doesn't match predefined categories.
    case other(Error)
    /// Represents a network-level connection error using `URLError`.
    case connection(URLError)
    /// Indicates a failure during request body encoding.
    case encoding(RequestEncodingError)
    /// Indicates a failure during response decoding.
    case decoding(RequestDecodingError)
    /// Represents an HTTP error based on a failed or unexpected status code.
    case statusCode(StatusCode)

    /// Initializes a `RequestError` by mapping from a general `Error`.
    ///
    /// If the input error matches known types (`URLError`, `DecodingError`, etc.),
    /// it is automatically wrapped in the appropriate `RequestError` case.
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
    /// Converts any `Error` into a standardized `RequestError`.
    var requestError: RequestError {
        return .init(self)
    }
}

// MARK: - RequestError + RequestErrorDescription

extension RequestError: RequestErrorDescription {
    /// A structured, descriptive identifier for the error case and its associated value.
    ///
    /// Used in logging and diagnostics to disambiguate failure sources.
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
