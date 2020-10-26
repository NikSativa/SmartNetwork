import Foundation
import UIKit
import NCallback

final
public class AnyRequestFactory<Error: AnyError>: RequestFactory {
    private let box: AbstractRequestFactory<Error>

    public init<K: RequestFactory>(_ provider: K) where K.Error == Error {
        self.box = RequestFactoryBox(provider)
    }

    public func requestCustomDecodable<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        box.requestCustomDecodable(type, with: parameters)
    }

    public func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        box.requestIgnorable(with: parameters)
    }

    public func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        box.requestDecodable(type, with: parameters)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        box.request(with: parameters)
    }

    public func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        box.requestImage(with: parameters)
    }

    public func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        box.requestOptionalImage(with: parameters)
    }

    public func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        box.requestData(with: parameters)
    }

    public func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        box.requestOptionalData(with: parameters)
    }

    public func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        box.requestAny(with: parameters)
    }

    public func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        box.requestOptionalAny(with: parameters)
    }
}

private class AbstractRequestFactory<Error: AnyError>: RequestFactory {
    func requestCustomDecodable<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        fatalError("abstract needs override")
    }

    func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        fatalError("abstract needs override")
    }

    func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        fatalError("abstract needs override")
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        fatalError("abstract needs override")
    }

    func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        fatalError("abstract needs override")
    }

    func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        fatalError("abstract needs override")
    }

    func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        fatalError("abstract needs override")
    }

    func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        fatalError("abstract needs override")
    }

    func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        fatalError("abstract needs override")
    }

    func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        fatalError("abstract needs override")
    }
}

final
private class RequestFactoryBox<T: RequestFactory>: AbstractRequestFactory<T.Error> {
    private var concrete: T

    init(_ concrete: T) {
        self.concrete = concrete
    }

    override func requestCustomDecodable<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        concrete.requestCustomDecodable(type, with: parameters)
    }

    override func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        concrete.requestIgnorable(with: parameters)
    }

    override func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        concrete.requestDecodable(type, with: parameters)
    }

    override func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        concrete.request(with: parameters)
    }

    override func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        concrete.requestImage(with: parameters)
    }

    override func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        concrete.requestOptionalImage(with: parameters)
    }

    override func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        concrete.requestData(with: parameters)
    }

    override func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        concrete.requestOptionalData(with: parameters)
    }

    override func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        concrete.requestAny(with: parameters)
    }

    override func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        concrete.requestOptionalAny(with: parameters)
    }
}
