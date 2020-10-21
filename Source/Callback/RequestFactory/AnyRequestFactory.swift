import Foundation
import UIKit
import NCallback

//final
//public class AnyRequestFactory<Error: AnyError> {
//    private let box: AbstractRequestFactory<Error>
//
//    public init<K: RequestFactory>(_ provider: K) where K.Error == Error {
//        self.box = RequestFactoryBox(provider)
//    }
//}
//
//extension AnyRequestFactory: RequestFactory {
//    public func request<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error> {
//        return box.request(type, with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
//        return box.request(with: parameters)
//    }
//
//    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
//        return box.request(with: parameters)
//    }
//}
//
//private class AbstractRequestFactory<Error: AnyError>: RequestFactory {
//    public func request<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
//        fatalError("abstract needs override")
//    }
//
//    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
//        fatalError("abstract needs override")
//    }
//}
//
//final
//private class RequestFactoryBox<T: RequestFactory>: AbstractRequestFactory<T.Error> {
//    private var concrete: T
//
//    init(_ concrete: T) {
//        self.concrete = concrete
//    }
//
//    override func request<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error> {
//        concrete.request(type, with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
//        concrete.request(with: parameters)
//    }
//
//    override func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
//        concrete.request(with: parameters)
//    }
//}
