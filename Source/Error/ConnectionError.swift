import Foundation

public enum ConnectionError: Error {
    case userAuthenticationRequired
    case notConnectedToInternet
    case networkConnectionLost
    case cannotConnectToHost
    case cannotFindHost
    case cancelled
    case timedOut

    public init?(_ error: URLError) {
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
            return nil
        }
    }
}
