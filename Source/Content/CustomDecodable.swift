import Foundation

public protocol CustomDecodable {
    associatedtype Object
    static func decode(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder) -> Result<Object, Error>
}
