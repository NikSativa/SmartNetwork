import Foundation
import Spry

import NCallback
@testable import NRequest

final
class FakeRequestFactory<Error: AnyError>: RequestFactory, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case request = "request(with:)"
    }

    func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return spryify(arguments: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return spryify(arguments: parameters)
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T?, Error> {
        return spryify(arguments: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        return spryify(arguments: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return spryify(arguments: parameters)
    }

    // MARK: - strong
    func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return spryify(arguments: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return spryify(arguments: parameters)
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return spryify(arguments: parameters)
    }

    func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return spryify(arguments: parameters)
    }
}
