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

extension RequestError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .generic:
            return 0
        case .connection:
            return 1
        case .encoding:
            return 2
        case .decoding:
            return 3
        case .statusCode:
            return 4
        }
    }
    
    public var errorUserInfo: [String : Any] {
        switch self {
        case .generic(let error):
            return error.errorUserInfo
        case .connection(let error):
            return error.errorUserInfo
        case .encoding(let error):
            return error.errorUserInfo
        case .decoding(let error):
            return error.errorUserInfo
        case .statusCode(let error):
            return error.errorUserInfo
        }
    }
}

public enum ConnectionError: Error, Equatable {
    case generic(URLError)
    case userAuthenticationRequired(URLError)
    case notConnectedToInternet(URLError)
    case networkConnectionLost(URLError)
    case cannotConnectToHost(URLError)
    case cannotFindHost(URLError)
    case cancelled(URLError)
    case timedOut(URLError)

    public init?(_ error: Swift.Error) {
        guard let error = error as? URLError else {
            return nil
        }

        switch error.code {
        case .notConnectedToInternet:
            self = .notConnectedToInternet(error)
        case .networkConnectionLost:
            self = .networkConnectionLost(error)
        case .cannotConnectToHost:
            self = .cannotConnectToHost(error)
        case .cannotFindHost:
            self = .cannotFindHost(error)
        case .cancelled:
            self = .cancelled(error)
        case .timedOut:
            self = .timedOut(error)
        case .userAuthenticationRequired:
            self = .userAuthenticationRequired(error)
        case .unknown:
            return nil
        default:
            self = .generic(error)
        }
    }
    
    private var urlError: URLError {
        switch self {
        case
                .generic(let error),
                .userAuthenticationRequired(let error),
                .notConnectedToInternet(let error),
                .networkConnectionLost(let error),
                .cannotConnectToHost(let error),
                .cannotFindHost(let error),
                .cancelled(let error),
                .timedOut(let error):
            return error
        }
    }
}

extension ConnectionError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .generic:
            return 0
        case .userAuthenticationRequired:
            return 1
        case .notConnectedToInternet:
            return 2
        case .networkConnectionLost:
            return 3
        case .cannotConnectToHost:
            return 4
        case .cannotFindHost:
            return 5
        case .cancelled:
            return 6
        case .timedOut:
            return 7
        }
    }
    
    public var errorUserInfo: [String : Any] {
        let urlError = urlError
        
        var info = [
            "url": urlError.failingURL as Any,
            "code": urlError.code
        ]
        
        if #available(iOS 13.0, *) {
            info["backgroundTaskCancelledReason"] = urlError.backgroundTaskCancelledReason
            info["networkUnavailableReason"] = urlError.networkUnavailableReason
        }
        
        return info
    }
}
