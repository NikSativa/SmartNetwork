import Foundation
import UIKit
import NCallback
import NQueue

final
public class BaseRequestFactory<Error: AnyError> {
    private enum State {
        case idle
        case refreshing
    }

    private typealias Key = ObjectIdentifier

    private let pluginProvider: PluginProvider?
    private let refreshToken: AnyRefreshToken<Error>?

    private class ScheduledRequest {
        private let prepare: () -> RequestInfo
        private let action: () -> Void
        private(set) var info: RequestInfo!

        init(prepare: @escaping @autoclosure () -> RequestInfo,
             action: @escaping @autoclosure () -> Void) {
            self.prepare = prepare
            self.action = action
        }

        func start() {
            info = prepare()
            action()
        }
    }

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var state: State = .idle

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var scheduledRequests: [Key: ScheduledRequest] = [:]
    private var scheduledParameters: [Key: Parameters] = [:]
    
    public init(pluginProvider: PluginProvider? = nil,
                refreshToken: AnyRefreshToken<Error>? = nil) {
        self.pluginProvider = pluginProvider
        self.refreshToken = refreshToken
    }

    private func request<Requestable: Request>(_ throwable: @autoclosure () throws -> Requestable) -> ResultCallback<Requestable.Response.Object, Requestable.Error>
    where Error == Requestable.Error {
        do {
            let request = try throwable()
            return refresh(request)
        } catch let error as Requestable.Error {
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

    private func unfreeze() {
        state = .idle
        $scheduledRequests.tryMutate {
            $0.values.forEach {
                $0.start()
            }
        }
    }

    private func refresh<T>(refreshToken: AnyRefreshToken<Error>,
                            actual: ResultCallback<T, Error>) {
        if state == .refreshing {
            return
        }
        state = .refreshing

        let factoryWithoutRefreshToken = Self(pluginProvider: pluginProvider)
        refreshToken.makeRequest(factoryWithoutRefreshToken).onComplete { [weak self] in
            self?.unfreeze()
        }
    }

    func removeFromCache<T>(_ actual: ResultCallback<T, Error>) {
        $scheduledRequests.tryMutate {
            $0[Key(actual)] = nil
        }
    }

    private func check<T>(actual: ResultCallback<T, Error>,
                          result: Result<T, Error>) {
        switch result {
        case .success:
            removeFromCache(actual)
            actual.complete(result)
        case .failure(let error):
            let scheduledRequest = $scheduledRequests.tryMutate {
                return $0[Key(actual)]
            }

            if let refreshToken = refreshToken,
               let scheduledRequest = scheduledRequest,
               let info = scheduledRequest.info {
                switch refreshToken.action(for: error, with: info) {
                case .passOver:
                    removeFromCache(actual)
                    actual.complete(error)
                case .retry:
                    scheduledRequest.start()
                case .refresh:
                    refresh(refreshToken: refreshToken, actual: actual)
                }
            } else {
                actual.complete(error)
            }
        }
    }

    private func refresh<Requestable: Request>(_ request: Requestable) -> ResultCallback<Requestable.Response.Object, Requestable.Error>
    where Error == Requestable.Error {
        typealias Callback = ResultCallback<Requestable.Response.Object, Requestable.Error>
        typealias ServiceClosure = Callback.ServiceClosure

        let start: ServiceClosure
        let stop: ServiceClosure

        if let _ = refreshToken {
            start = { [weak self] actual in
                guard let self = self else {
                    request.start()
                    return
                }

                let callback: ScheduledRequest = .init(prepare: request.prepare(),
                                                       action: request.start())
                self.$scheduledRequests.tryMutate {
                    $0[Key(actual)] = callback
                }

                if self.state == .idle {
                    callback.start()
                }
            }

            stop = { [weak self] actual in
                self?.removeFromCache(actual)
                request.stop()
            }
        } else {
            start = { _ in
                request.start()
            }

            stop = { _ in
                request.stop()
            }
        }

        let callback = Callback(start: start, stop: stop)
        request.onComplete { [weak callback, weak self] result in
            if let self = self, let callback = callback {
                self.check(actual: callback, result: result)
            } else {
                callback?.complete(result)
            }
        }
        return callback
    }
}

extension BaseRequestFactory: RequestFactory {
    public func prepare(_ parameters: Parameters) throws -> URLRequest {
        let parameters = modify(parameters)
        return try parameters.sdkRequest()
    }

    public func requestCustomDecodable<T: CustomDecodable>(_: T.Type, with parameters: Parameters) -> ResultCallback<T.Object, T.Error>
    where Error == T.Error {
        let parameters = modify(parameters)
        return request(try Impl.Request<T, T.Error>(parameters))
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
