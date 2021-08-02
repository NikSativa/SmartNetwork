import Foundation

public protocol CustomizedDecodable: Decodable {
    static var decoder: JSONDecoder { get }
}

extension Array: CustomizedDecodable where Element: CustomizedDecodable {
    public static var decoder: JSONDecoder {
        return Element.decoder
    }
}

extension Dictionary: CustomizedDecodable where Value: CustomizedDecodable, Key: Decodable {
    public static var decoder: JSONDecoder {
        return Value.decoder
    }
}
