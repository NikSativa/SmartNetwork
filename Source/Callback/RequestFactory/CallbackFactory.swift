import Foundation
import UIKit
import NCallback

#if canImport(NRequest)
import NRequest
#endif

public protocol CallbackFactory: class {
    associatedtype Error: AnyError

    func request<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error>

    /// proxy helpers
    func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error>
    func requestIgnorable(with parameters: Parameters) -> ResultCallback<Void, Error>

    func request<R: Decodable>(_: R.Type, with parameters: Parameters) -> ResultCallback<R, Error>
    func request<R: Decodable>(with parameters: Parameters) -> ResultCallback<R, Error>

    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error>
    func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error>

    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error>
    func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error>

    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error>
    func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error>

    /// convert to AnyRequestFactory
    func toAny() -> AnyRequestFactory<Error>
}

public extension RequestFactory {
    // MARK -
    func toAny() -> AnyRequestFactory<Error> {
        if let self = self as? AnyRequestFactory<Error> {
            return self
        }

        return AnyRequestFactory(self)
    }
}
