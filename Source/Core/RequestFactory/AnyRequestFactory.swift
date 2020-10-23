import Foundation
import UIKit
import NCallback

final
public class AnyRequestFactory<Error: AnyError>: RequestFactory {
    private let box: AbstractRequestFactory<Error>

    public init<K: RequestFactory>(_ provider: K) where K.Error == Error {
        self.box = RequestFactoryBox(provider)
    }

    public func request<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        box.request(type, with: parameters)
    }
}

private class AbstractRequestFactory<Error: AnyError>: RequestFactory {
    func request<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        fatalError("abstract needs override")
    }
}

final
private class RequestFactoryBox<T: RequestFactory>: AbstractRequestFactory<T.Error> {
    private var concrete: T

    init(_ concrete: T) {
        self.concrete = concrete
    }

    override func request<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        concrete.request(type, with: parameters)
    }
}
