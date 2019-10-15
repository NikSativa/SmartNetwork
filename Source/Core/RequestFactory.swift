import Foundation
import UIKit

public class RequestFactory {
    public init() {
    }

    // MARK: - weak
    public func request(with parameters: Parameters) -> Callback<UIImage?, Error> {
        return request(try Request<ImageContent>(parameters))
    }

    public func request(with parameters: Parameters) -> Callback<Data?, Error> {
        return request(try Request<DataContent>(parameters))
    }

    public func request<T: Decodable>(with parameters: Parameters) -> Callback<T?, Error> {
        return request(try Request<DecodableContent>(parameters))
    }

    public func request(with parameters: Parameters) -> Callback<IgnorableResult, Error> {
        return request(try Request<IgnorableContent>(parameters))
    }

    public func request(with parameters: Parameters) -> Callback<Any?, Error> {
        return request(try Request<JSONContent>(parameters))
    }

    // MARK: - strong
    public func request(with parameters: Parameters) -> Callback<UIImage, Error> {
        return request(try Request<ImageContent>(parameters)).flatMap(RequestFactory.strongify)
    }

    public func request(with parameters: Parameters) -> Callback<Data, Error> {
        return request(try Request<DataContent>(parameters)).flatMap(RequestFactory.strongify)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> Callback<T, Error> {
        return request(try Request<DecodableContent>(parameters)).flatMap(RequestFactory.strongify)
    }

    public func request(with parameters: Parameters) -> Callback<Any, Error> {
        return request(try Request<JSONContent>(parameters)).flatMap(RequestFactory.strongify)
    }

    // MARK: - helpers
    private func request<T, R: Requestable>(_ throwable: @autoclosure () throws -> R) -> Callback<T, Error> where R.ResponseType == T {
        do {
            return Callback(request: try throwable())
        }
        catch let error {
            return Callback.failure(error)
        }
    }

    private static func strongify<R>(_ result: Result<R?, Error>) -> Result<R, Error> {
        switch result {
        case .success(let value):
            if let value = value {
                return .success(value)
            } else {
                return .failure(DecodingError.nilResponse)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
}
