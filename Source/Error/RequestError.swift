import Foundation

public enum RequestError: Error {
    case generic
    case other(Error)
    case connection(URLError)
    case encoding(RequestEncodingError)
    case decoding(RequestDecodingError)
    case statusCode(StatusCode)

    public init(_ error: Swift.Error) {
        switch error {
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
