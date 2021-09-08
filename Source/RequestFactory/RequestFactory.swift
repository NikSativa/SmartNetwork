import Foundation
import UIKit
import NCallback

public protocol RequestFactory {
    associatedtype Error: AnyError

    func prepare(_: Parameters) throws -> URLRequest

    func requestCustomDecodable<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error>
    where T.Error == Error

    // MARK - Void
    func requestVoid(with parameters: Parameters) -> ResultCallback<Void, Error>

    // MARK - Decodable
    func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error>
    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error>

    // MARK - Image
    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error>
    func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error>

    // MARK - Data
    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error>
    func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error>

    // MARK - Any/JSON
    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error>
    func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error>
}

// MARK - proxy method for Fake
public extension RequestFactory {
    // MARK - Void
    func requestVoid(with parameters: Parameters) -> ResultCallback<Void, Error> {
        requestCustomDecodable(VoidContent<Error>.self, with: parameters)
    }

    // MARK - Decodable
    func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        requestCustomDecodable(DecodableContent<T, Error>.self, with: parameters)
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        requestDecodable(T.self, with: parameters)
    }

    // MARK - Image
    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        requestCustomDecodable(ImageContent<Error>.self, with: parameters)
    }

    func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        requestCustomDecodable(OptionalImageContent<Error>.self, with: parameters)
    }

    // MARK - Data
    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        requestCustomDecodable(DataContent<Error>.self, with: parameters)
    }

    func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        requestCustomDecodable(OptionalDataContent<Error>.self, with: parameters)
    }

    // MARK - Any/JSON
    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        requestCustomDecodable(JSONContent<Error>.self, with: parameters)
    }

    func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        requestCustomDecodable(OptionalJSONContent<Error>.self, with: parameters)
    }
}

// only proxy without `faking`
public extension RequestFactory {
    // MARK - Void
    func request(with parameters: Parameters) -> ResultCallback<Void, Error> {
        requestVoid(with: parameters)
    }

    // MARK - Decodable
    func request<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        requestDecodable(type, with: parameters)
    }

    // MARK - Image
    func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        requestImage(with: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        requestOptionalImage(with: parameters)
    }

    // MARK - Data
    func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        requestData(with: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        requestOptionalData(with: parameters)
    }

    // MARK - Any/JSON
    func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        requestAny(with: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        requestOptionalAny(with: parameters)
    }

    func toAny() -> AnyRequestFactory<Error> {
        if let self = self as? AnyRequestFactory<Error> {
            return self
        }

        return AnyRequestFactory(self)
    }
}
