import Foundation

public enum EncodingError: AnyError {
    case generic(GenericError)
    case lackParameters
    case lackAdress
    case cantEncodeImage
    case invalidJSON

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
