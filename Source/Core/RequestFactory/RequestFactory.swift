import Foundation
import UIKit
import NCallback

public protocol RequestFactory: class {
    associatedtype Error: AnyError

    func request<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error>
}

public extension RequestFactory {
    // MARK - Ignorable
    func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        request(IgnorableContent<Error>.self, with: parameters)
    }

    // MARK - Decodable
    func request<T: Decodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        request(DecodableContent<T, Error>.self, with: parameters)
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        request(DecodableContent<T, Error>.self, with: parameters)
    }

    // MARK - Image
    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        request(ImageContent<Error>.self, with: parameters)
    }

    func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        request(OptionalImageContent<Error>.self, with: parameters)
    }

    // MARK - Data
    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        request(DataContent<Error>.self, with: parameters)
    }

    func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        request(OptionalDataContent<Error>.self, with: parameters)
    }

    // MARK - Any/JSON
    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        request(JSONContent<Error>.self, with: parameters)
    }

    func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        request(OptionalJSONContent<Error>.self, with: parameters)
    }

    // MARK -
    func toAny() -> AnyRequestFactory<Error> {
        if let self = self as? AnyRequestFactory<Error> {
            return self
        }

        return AnyRequestFactory(self)
    }
}
