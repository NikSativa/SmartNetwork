import Foundation

public enum DecodingError: Error {
    case other(Error)
    case brokenResponse
    case nilResponse
}
