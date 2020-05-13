import Foundation
import Spry

@testable import NRequest

class FakeRequestFactory: RequestFactory, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case request = "request(with:)"
    }

    override func request(with parameters: Parameters) -> Callback<UIImage?, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> Callback<Data?, Error> {
        return spryify(arguments: parameters)
    }

    override func request<T: Decodable>(with parameters: Parameters) -> Callback<T?, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> Callback<IgnorableResult, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> Callback<Any?, Error> {
        return spryify(arguments: parameters)
    }

    // MARK: - strong
    override func request(with parameters: Parameters) -> Callback<UIImage, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> Callback<Data, Error> {
        return spryify(arguments: parameters)
    }

    override func request<T: Decodable>(with parameters: Parameters) -> Callback<T, Error> {
        return spryify(arguments: parameters)
    }

    override func request(with parameters: Parameters) -> Callback<Any, Error> {
        return spryify(arguments: parameters)
    }
}
