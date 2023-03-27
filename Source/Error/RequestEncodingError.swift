import Foundation

public enum RequestEncodingError: Error {
    case other(EncodingError)
    case lackParameters
    case lackAdress
    case cantEncodeImage
    case invalidJSON
}
