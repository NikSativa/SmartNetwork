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
    public func request<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error> {
        let parameters = modify(parameters)
        return request(try RealRequest<T, T.Error>(parameters))
    }
}
