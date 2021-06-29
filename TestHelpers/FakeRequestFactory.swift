import Foundation
import UIKit
import NSpry

import NCallback
@testable import NRequest

public final
class FakeRequestFactory<Error: AnyError>: RequestFactory, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:)"
        case requestCustomDecodable = "requestCustomDecodable(_:with:)"
        case requestIgnorable = "requestIgnorable(with:)"
        case requestDecodable = "requestDecodable(_:with:)"
        case request = "request(with:)"
        case requestImage = "requestImage(with:)"
        case requestOptionalImage = "requestOptionalImage(with:)"
        case requestData = "requestData(with:)"
        case requestOptionalData = "requestOptionalData(with:)"
        case requestAny = "requestAny(with:)"
        case requestOptionalAny = "requestOptionalAny(with:)"
    }

    public init() {
    }

    public func prepare(_ parameters: Parameters) throws -> URLRequest {
        return spryify(arguments: parameters)
    }

    public func requestCustomDecodable<T: CustomDecodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        return spryify(arguments: type, parameters)
    }

    // MARK - Ignorable
    public func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        return spryify(arguments: parameters)
    }

    // MARK - Decodable
    public func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        return spryify(arguments: type, parameters)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return spryify(arguments: parameters)
    }

    // MARK - Image
    public func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return spryify(arguments: parameters)
    }

    public func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return spryify(arguments: parameters)
    }

    // MARK - Data
    public func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return spryify(arguments: parameters)
    }

    public func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return spryify(arguments: parameters)
    }

    // MARK - Any/JSON
    public func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return spryify(arguments: parameters)
    }

    public func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return spryify(arguments: parameters)
    }
}
