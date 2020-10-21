import Foundation

public enum DecodingError: Error, Equatable {
    case brokenResponse
    case nilResponse
}
