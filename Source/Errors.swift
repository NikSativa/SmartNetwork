import Foundation

public enum EncodingError: Error {
    public enum Body {
        case cantSerialize(Error)
        case cantEncode(Error)
        case cantEncodeImage
        case invalidJSON
    }

    case lackAdress
    case body(Body)
}

public enum DecodingError: Error {
    case nilResponse
    case cantSerialize(Error)
    case cantDecode(Error)
}
