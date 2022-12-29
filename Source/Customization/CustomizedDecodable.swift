import Foundation

public protocol CustomizedDecodable: Decodable {
    static var decoder: JSONDecoder { get }
}

// MARK: - Array + CustomizedDecodable

extension Array: CustomizedDecodable where Element: CustomizedDecodable {
    public static var decoder: JSONDecoder {
        return Element.decoder
    }
}

// MARK: - Dictionary + CustomizedDecodable

extension Dictionary: CustomizedDecodable where Value: CustomizedDecodable, Key: Decodable {
    public static var decoder: JSONDecoder {
        return Value.decoder
    }
}
