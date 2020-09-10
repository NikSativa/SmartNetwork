import Foundation

public enum DecodingError: AnyError {
    case generic(GenericError)
    case brokenResponse
    case nilResponse

    public init(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        default:
            self = .init(GenericError(error))
        }
    }

    public init(_ error: GenericError) {
        self = .generic(error)
    }
}
