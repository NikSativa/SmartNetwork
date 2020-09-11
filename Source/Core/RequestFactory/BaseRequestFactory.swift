import Foundation
import UIKit
import NCallback

public class BaseRequestFactory<Error: AnyError> {
    private let pluginProvider: PluginProvider?

    public init(pluginProvider: PluginProvider? = nil) {
        self.pluginProvider = pluginProvider
    }

    private func request<Response: InternalDecodable>(_ throwable: @autoclosure () throws -> Request<Response, Error>) -> ResultCallback<Response.Object, Error> {
        do {
            return Callback(request: try throwable())
        }
        catch let error as Error {
            return Callback.failure(error)
        } catch let error {
            return Callback.failure(Error.wrap(error))
        }
    }

    private static func strongify<R>(_ result: Result<R?, Error>) -> Result<R, Error> {
        switch result {
        case .success(let value):
            if let value = value {
                return .success(value)
            } else {
                return .failure(Error.wrap(RequestError.decoding(.nilResponse)))
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
    public func request(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        let parameters = modify(parameters)
        return request(try Request<IgnorableContent, Error>(parameters))
    }

    // MARK: - weak
    public func request(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        let parameters = modify(parameters)
        return request(try Request<ImageContent, Error>(parameters))
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        let parameters = modify(parameters)
        return request(try Request<DataContent, Error>(parameters))
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        let parameters = modify(parameters)
        return request(try Request<JSONContent, Error>(parameters))
    }

    // MARK: - strong
    public func request(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        let parameters = modify(parameters)
        return request(try Request<ImageContent, Error>(parameters)).flatMap(Self.strongify)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Data, Error> {
        let parameters = modify(parameters)
        return request(try Request<DataContent, Error>(parameters)).flatMap(Self.strongify)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        let parameters = modify(parameters)
        return request(try Request<DecodableContent, Error>(parameters)).flatMap(Self.strongify)
    }

    public func request(with parameters: Parameters) -> ResultCallback<Any, Error> {
        let parameters = modify(parameters)
        return request(try Request<JSONContent, Error>(parameters)).flatMap(Self.strongify)
    }
}
