import Foundation

public enum StatusCode: Error, Equatable {
    case noContent // 204
    case badRequest // 400
    case unauthorized // 401
    case forbidden // 403
    case notFound // 404
    case timeout // 408
    case upgradeRequired // 426
    case serverError // 500
    case other(Int)
}

public extension StatusCode {
    func toInt() -> Int {
        switch self {
        case .noContent:
            return 204
        case .badRequest:
            return 400
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        case .timeout:
            return 408
        case .upgradeRequired:
            return 426
        case .serverError:
            return 500
        case .other(let code):
            return code
        }
    }
}

public extension StatusCode {
    init?(_ code: Int?) {
        guard let code = code else {
            return nil
        }

        switch code {
        case 200:
            return nil
        case 204:
            self = .noContent
        case 400:
            self = .badRequest
        case 401:
            self = .unauthorized
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 408:
            self = .timeout
        case 426:
            self = .upgradeRequired
        case 500:
            self = .serverError
        default:
            self = .other(code)
        }
    }
}
