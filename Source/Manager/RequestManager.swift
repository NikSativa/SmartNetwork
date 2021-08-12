import Foundation
import UIKit
import NCallback

// sourcery: fakable
public protocol RequestManager {
    associatedtype Error: AnyError

    func requestCustomDecodable<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error>

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
public extension RequestManager {
    // MARK - Void
    func requestVoid(with parameters: Parameters) -> ResultCallback<Void, Error> {
        return requestCustomDecodable(VoidContent.self, with: parameters)
    }

    // MARK - Decodable
    func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        return requestCustomDecodable(DecodableContent<T>.self, with: parameters).recoverResponse()
    }

    func requestOptionalDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T?, Error> {
        return requestCustomDecodable(DecodableContent<T>.self, with: parameters)
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return requestDecodable(T.self, with: parameters)
    }

    // MARK - Image
    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return requestCustomDecodable(ImageContent.self, with: parameters).recoverResponse()
    }

    func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return requestCustomDecodable(ImageContent.self, with: parameters)
    }

    // MARK - Data
    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return requestCustomDecodable(DataContent.self, with: parameters).recoverResponse()
    }

    func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return requestCustomDecodable(DataContent.self, with: parameters)
    }

    // MARK - Any/JSON
    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return requestCustomDecodable(JSONContent.self, with: parameters).recoverResponse()
    }

    func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return requestCustomDecodable(JSONContent.self, with: parameters)
    }
}

// only proxy without `faking`
public extension RequestManager {
    // MARK - Void
    func request(with parameters: Parameters) -> ResultCallback<Void, Error> {
        return requestVoid(with: parameters)
    }

    // MARK - Decodable
    func request<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        return requestDecodable(type, with: parameters)
    }

    // MARK - Image
    func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return requestImage(with: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return requestOptionalImage(with: parameters)
    }

    // MARK - Data
    func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return requestData(with: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return requestOptionalData(with: parameters)
    }

    // MARK - Any/JSON
    func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return requestAny(with: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return requestOptionalAny(with: parameters)
    }

    func toAny() -> AnyRequestManager<Error> {
        if let self = self as? AnyRequestManager<Error> {
            return self
        }

        return AnyRequestManager(self)
    }
}

private extension Callback {
    func recoverResponse<T, Error: AnyError>() -> ResultCallback<T, Error>
    where ResultType == Result<T?, Error> {
        return flatMap { result in
            switch result {
            case .success(.some(let response)):
                return .success(response)
            case .success(.none):
                return .failure(.wrap(DecodingError.nilResponse))
            case .failure(let error):
                return .failure(error)
            }
        }
    }
}
