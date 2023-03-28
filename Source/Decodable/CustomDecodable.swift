import Foundation

public protocol CustomDecodable {
    associatedtype Object

    var result: Result<Object, Error> { get }

    init(with data: RequestResult, decoder: @autoclosure () -> JSONDecoder)
}
