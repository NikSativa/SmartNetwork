import Foundation

public enum DecodingError: Error, Equatable {
    case generic(EquatableError)
    case brokenResponse
    case nilResponse
}
