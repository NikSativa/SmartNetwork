import Foundation

public enum RequestError: AnyError {
    case generic(EquatableError)
    case connection(ConnectionError)
    case encoding(EncodingError)
    case decoding(DecodingError)
    case statusCode(StatusCode)

    public init?(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        case let error as ConnectionError:
            self = .connection(error)
        case let error as EncodingError:
            self = .encoding(error)
        case let error as DecodingError:
            self = .decoding(error)
        case let error as StatusCode:
            self = .statusCode(error)
        default:
            if let error = ConnectionError(error) {
                self = .connection(error)
            } else {
                return nil
            }
        }
    }

    public init(_ error: EquatableError) {
        self = .generic(error)
    }
}

public enum ConnectionError: Error, Equatable {
    case generic(URLError)
    case userAuthenticationRequired
    case notConnectedToInternet
    case networkConnectionLost
    case cannotConnectToHost
    case cannotFindHost
    case cancelled
    case timedOut

    public init?(_ error: Swift.Error) {
        guard let error = error as? URLError else {
            return nil
        }

        switch error.code {
        case .notConnectedToInternet:
            self = .notConnectedToInternet
        case .networkConnectionLost:
            self = .networkConnectionLost
        case .cannotConnectToHost:
            self = .cannotConnectToHost
        case .cannotFindHost:
            self = .cannotFindHost
        case .cancelled:
            self = .cancelled
        case .timedOut:
            self = .timedOut
        case .userAuthenticationRequired:
            self = .userAuthenticationRequired
        case .unknown:
            return nil
        default:
            self = .generic(error)
        }
    }
}
