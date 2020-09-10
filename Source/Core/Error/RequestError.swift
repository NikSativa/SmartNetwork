import Foundation

public enum RequestError: AnyError {
    case generic(GenericError)
    case encoding(EncodingError)
    case decoding(DecodingError)
    case statusCode(StatusCode)

    public init?(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        case let error as EncodingError:
            self = .encoding(error)
        case let error as DecodingError:
            self = .decoding(error)
        case let error as StatusCode:
            self = .statusCode(error)
        default:
            return nil
        }
    }

    public init(_ error: GenericError) {
        self = .generic(error)
    }
}
