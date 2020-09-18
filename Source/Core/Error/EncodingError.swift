import Foundation

public enum EncodingError: AnyError {
    case generic(EquatableError)
    case lackParameters
    case lackAdress
    case cantEncodeImage
    case invalidJSON

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
