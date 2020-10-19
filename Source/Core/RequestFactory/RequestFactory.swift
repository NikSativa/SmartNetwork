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
    func request<T: CustomDecodable>(_ : T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error>

    /// convert to AnyRequestFactory
    func toAny() -> AnyRequestFactory<Error>
}

public extension RequestFactory {
    func request<T: Decodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        request(with: parameters)
    }

    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        request(with: parameters)
    }

    func requestData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        request(with: parameters)
    }

    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        request(with: parameters)
    }

    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        request(with: parameters)
    }

    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        request(with: parameters)
    }

    func requestAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        request(with: parameters)
    }

    func toAny() -> AnyRequestFactory<Error> {
        if let self = self as? AnyRequestFactory<Error> {
            return self
        }

        return AnyRequestFactory(self)
    }
}
