import Foundation
import UIKit
import NCallback

final
public class BaseRequestFactory<Error: AnyError> {
    private typealias RealRequest = Impl.Request
    private let pluginProvider: PluginProvider?
    private let refreshToken: RefreshToken?

    public init(pluginProvider: PluginProvider? = nil,
                refreshToken: RefreshToken? = nil) {
        self.pluginProvider = pluginProvider
        self.refreshToken = refreshToken
    }

    private func request<Response: CustomDecodable>(_ throwable: @autoclosure () throws -> RealRequest<Response, Error>) -> ResultCallback<Response.Object, Error> {
        do {
            let request = try throwable()
            return Callback(request: request)
        } catch let error as Error {
            return Callback.failure(error)
        } catch let error {
            return Callback.failure(.wrap(error))
        }
    }

    private static func strongify<R>(_ result: Result<R?, Error>) -> Result<R, Error> {
        switch result {
        case .success(let value):
            if let value = value {
                return .success(value)
            } else {
                return .failure(.wrap(DecodingError.nilResponse))
            }
        case .failure(let error):
            return .failure(error)
        }
    }

    private func modify(_ parameters: Parameters) -> Parameters {
        if let plugins = pluginProvider?.plugins(), !plugins.isEmpty {
            return parameters + plugins
        }
        return parameters
    }
}

extension BaseRequestFactory: RequestFactory {
    public func request<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, Error> {
        let parameters = modify(parameters)
        return request(try RealRequest<T, Error>(parameters))
    }

    public func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        return request(IgnorableContent.self, with: parameters)
    }

    // MARK: - weak
    public func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return request(ImageContent.self, with: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return request(DataContent.self, with: parameters)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return request(JSONContent.self, with: parameters)
    }

    // MARK: - strong
    public func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return request(ImageContent.self, with: parameters).flatMap(Self.strongify)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return request(DataContent.self, with: parameters).flatMap(Self.strongify)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return request(DecodableContent.self, with: parameters).flatMap(Self.strongify)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return request(JSONContent.self, with: parameters).flatMap(Self.strongify)
    }
}
