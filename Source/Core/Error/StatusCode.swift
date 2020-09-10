import Foundation

public enum StatusCode: Error, Equatable, ErrorMapping {
    case noContent    // 204
    case badRequest   // 400
    case unauthorized // 401
    case notFound     // 404
    case serverError  // 500
    case other(Int)

    public static func verify(_ code: Int?) throws {
        guard let code = code else {
            return
        }

        switch code {
        case 200:
            break
        case 204:
            throw noContent
        case 400:
            throw badRequest
        case 401:
            throw unauthorized
        case 404:
            throw notFound
        case 500:
            throw serverError
        default:
            throw other(code)
        }
    }
}
