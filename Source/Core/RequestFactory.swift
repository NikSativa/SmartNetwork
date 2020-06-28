import Foundation
import UIKit

public class RequestFactory {
    public init() {
    }

    // MARK: - weak
    public func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return request(try Request<ImageContent, Error>(parameters))
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return request(try Request<DataContent, Error>(parameters))
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T?, Error> {
        return request(try Request<DecodableContent, Error>(parameters))
    }

    public func request(with parameters: Parameters) -> ResultCallback<IgnorableResult, Error> {
        return request(try Request<IgnorableContent, Error>(parameters))
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return request(try Request<JSONContent, Error>(parameters))
    }

    // MARK: - strong
    public func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return request(try Request<ImageContent, Error>(parameters)).flatMap(RequestFactory.strongify)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return request(try Request<DataContent, Error>(parameters)).flatMap(RequestFactory.strongify)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return request(try Request<DecodableContent, Error>(parameters)).flatMap(RequestFactory.strongify)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return request(try Request<JSONContent, Error>(parameters)).flatMap(RequestFactory.strongify)
    }

    // MARK: - helpers
    private func request<T, R: Requestable>(_ throwable: @autoclosure () throws -> R) -> ResultCallback<T, Error> where R.ResponseType == T {
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
