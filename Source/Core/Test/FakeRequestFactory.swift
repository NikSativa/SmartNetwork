import Foundation
import Spry

import NCallback
@testable import NRequest

final
class FakeRequestFactory: RequestFactory, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case request = "request(with:)"
    }

    override func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return spryify(arguments: parameters)
    }

    override func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T?, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> ResultCallback<IgnorableResult, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return spryify(arguments: parameters)
    }

    // MARK: - strong
    override func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return spryify(arguments: parameters)
    }

    override func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return spryify(arguments: parameters)
    }
}
