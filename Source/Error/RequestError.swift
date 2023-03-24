import Foundation

public enum RequestError: Error {
    case generic
    case other(Error)
    case connection(URLError, ConnectionError?)
    case encoding(EncodingError)
    case decoding(DecodingError)
    case statusCode(StatusCode)

    public init(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        case let error as URLError:
            self = .connection(error, ConnectionError(error))
        case let error as EncodingError:
            self = .encoding(error)
        case let error as Swift.EncodingError:
            self = .encoding(.other(error))
        case let error as DecodingError:
            self = .decoding(error)
        case let error as Swift.DecodingError:
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
