import Foundation

public enum EncodingError: Error, Equatable {
    case generic(EquatableError)
    case lackParameters
    case lackAdress
    case cantEncodeImage
    case invalidJSON
}
