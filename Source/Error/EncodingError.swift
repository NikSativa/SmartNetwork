import Foundation

public enum EncodingError: Error {
    case other(Error)
    case lackParameters
    case lackAdress
    case cantEncodeImage
    case invalidJSON
}
