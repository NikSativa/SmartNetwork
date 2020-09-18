import Foundation

public enum DecodingError: AnyError {
    case generic(EquatableError)
    case brokenResponse
    case nilResponse

    public init(_ error: Swift.Error) {
        switch error {
        case let error as Self:
            self = error
        default:
            self = .init(EquatableError(error))
        }
    }

    public init(_ error: EquatableError) {
        self = .generic(error)
    }
}
