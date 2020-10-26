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

    private func request<Response>(_ throwable: @autoclosure () throws -> RealRequest<Response, Response.Error>) -> ResultCallback<Response.Object, Response.Error>
    where Response: CustomDecodable {
        do {
            let request = try throwable()
            return Callback(request: request)
        } catch let error as Response.Error {
            return Callback.failure(error)
        } catch let error {
            return Callback.failure(.wrap(error))
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
    public func requestCustomDecodable<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        let parameters = modify(parameters)
        return request(try RealRequest<T, T.Error>(parameters))
    }

    // MARK - Ignorable
    public func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        requestCustomDecodable(IgnorableContent<Error>.self, with: parameters)
    }

    // MARK - Decodable
    public func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        requestCustomDecodable(DecodableContent<T, Error>.self, with: parameters)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        requestDecodable(T.self, with: parameters)
    }

    // MARK - Image
    public func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        requestCustomDecodable(ImageContent<Error>.self, with: parameters)
    }

    public func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        requestCustomDecodable(OptionalImageContent<Error>.self, with: parameters)
    }

    // MARK - Data
    public func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        requestCustomDecodable(DataContent<Error>.self, with: parameters)
    }

    public func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        requestCustomDecodable(OptionalDataContent<Error>.self, with: parameters)
    }

    // MARK - Any/JSON
    public func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        requestCustomDecodable(JSONContent<Error>.self, with: parameters)
    }

    public func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        requestCustomDecodable(OptionalJSONContent<Error>.self, with: parameters)
    }
}
