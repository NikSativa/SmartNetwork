import Foundation

public protocol CustomizedEncodable: Encodable {
    static var encoder: JSONEncoder { get }
}
