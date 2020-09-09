import Foundation

public protocol CustomizedDecodable: Decodable {
    static var decoder: JSONDecoder { get }
}
