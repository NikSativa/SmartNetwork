import Foundation
import UIKit
import NCallback

public protocol RequestFactory: class {
    associatedtype Error: AnyError

    func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error>

    func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error>
    func request(with parameters: Parameters) -> ResultCallback<Data?, Error>
    func request(with parameters: Parameters) -> ResultCallback<Any?, Error>

    func request(with parameters: Parameters) -> ResultCallback<UIImage, Error>
    func request(with parameters: Parameters) -> ResultCallback<Data, Error>
    func request(with parameters: Parameters) -> ResultCallback<Any, Error>

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error>

    /// proxy helper
    func request<T: Decodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T, Error>

    /// convert to AnyRequestFactory
    func toAny() -> AnyRequestFactory<Error>
}

public extension RequestFactory {
    func request<T: Decodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        request(with: parameters)
    }
}
