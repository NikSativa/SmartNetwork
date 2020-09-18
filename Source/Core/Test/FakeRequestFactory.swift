import Foundation
import Spry

import NCallback
@testable import NRequest

public final
class FakeRequestFactory<Error: AnyError>: RequestFactory, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case request = "request(with:)"
    }

    public init() {
    }

    public func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return spryify(arguments: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return spryify(arguments: parameters)
    }

    func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T?, Error> {
        return spryify(arguments: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        return spryify(arguments: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return spryify(arguments: parameters)
    }

    // MARK: - strong
    public func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return spryify(arguments: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return spryify(arguments: parameters)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return spryify(arguments: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return spryify(arguments: parameters)
    }
}
