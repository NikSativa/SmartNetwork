import Foundation

public enum RequestDecodingError: Error {
    case other(DecodingError)
    case brokenResponse
    case nilResponse
}
