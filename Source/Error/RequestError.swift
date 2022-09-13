import Foundation

public enum RequestError: AnyError {
    case generic(EquatableError)
    case connection(URLError, ConnectionError?)
    case encoding(EncodingError)
    case decoding(DecodingError)
    case statusCode(StatusCode)

    public init?(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        case let error as URLError:
            self = .connection(error, ConnectionError(error))
        case let error as EncodingError:
            self = .encoding(error)
        case let error as Swift.EncodingError:
            self = .encoding(.generic(.init(error)))
        case let error as DecodingError:
            self = .decoding(error)
        case let error as Swift.DecodingError:
            self = .decoding(.generic(.init(error)))
        case let error as StatusCode:
            self = .statusCode(error)
        default:
            return nil
        }
    }

    public init(_ error: EquatableError) {
        self = .generic(error)
    }
}
