import Foundation
import UIKit
import NCallback
import NQueue

public final class BaseRequestFactory<Error: AnyError> {
    private enum State {
        case idle
        case refreshing
    }

    private typealias Key = ObjectIdentifier

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var state: State = .idle

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var scheduledRequests: [Key: ScheduledRequest] = [:]
    private var scheduledParameters: [Key: Parameters] = [:]

    private let pluginProvider: PluginProvider?
    private let stopTheLine: AnyStopTheLine<Error>?

    public init(pluginProvider: PluginProvider? = nil,
                stopTheLine: AnyStopTheLine<Error>? = nil) {
        self.pluginProvider = pluginProvider
        self.stopTheLine = stopTheLine
    }

    private func modify(_ parameters: Parameters) -> Parameters {
        if let plugins = pluginProvider?.plugins(),
           !plugins.isEmpty {
            var new = parameters
            new.plugins += plugins
            return new
        }
        return parameters
    }

    private func unfreeze() {
        state = .idle

        let scheduledRequests = self.scheduledRequests
        for request in scheduledRequests.values.filter({ !$0.isSpecial }) {
            request.start()
        }
    }

    private func refresh(refreshToken: AnyStopTheLine<Error>,
                         request: ScheduledRequest,
                         error: Error) {
        if state == .refreshing {
            return
        }
        state = .refreshing

        let stopTheLineFactory = Self(pluginProvider: pluginProvider).toAny()
        refreshToken.makeRequest(stopTheLineFactory,
                                 request: request,
                                 error: error).onComplete { [weak self] in
                                    self?.unfreeze()
                                 }
    }

    func removeFromCache<T>(_ actual: ResultCallback<T, Error>) {
        $scheduledRequests.mutate {
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
            if let refreshToken = stopTheLine {
                let scheduledRequest = $scheduledRequests.mutate {
                    return $0[Key(actual)]
                }

                if let scheduledRequest = scheduledRequest {
                    let info = scheduledRequest.info
                    switch refreshToken.action(for: error, with: info) {
                    case .passOver:
                        removeFromCache(actual)
                        actual.complete(error)
                    case .retry:
                        scheduledRequest.start()
                    case .stopTheLine:
                        refresh(refreshToken: refreshToken,
                                request: scheduledRequest,
                                error: error)
                    }
                } else {
                    actual.complete(error)
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

        if let _ = stopTheLine {
            start = { [weak self] actual in
                guard let self = self else {
                    request.start()
                    return
                }

                self.$scheduledRequests.mutate {
                    $0[Key(actual)] = request
                }

                if self.state == .idle || request.isSpecial {
                    request.start()
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
        do {
            let request = try Impl.Request<T, T.Error>(parameters: parameters)
            return refresh(request)
        } catch let error as T.Error {
            return Callback.failure(error)
        } catch let error {
            return Callback.failure(.wrap(error))
        }
    }

    // MARK - Ignorable
    public func requestIgnorable(with parameters: Parameters) -> ResultCallback<Ignorable, Error> {
        return requestCustomDecodable(IgnorableContent<Error>.self, with: parameters)
    }

    // MARK - Decodable
    public func requestDecodable<T: Decodable>(_ type: T.Type, with parameters: Parameters) -> ResultCallback<T, Error> {
        return requestCustomDecodable(DecodableContent<T, Error>.self, with: parameters)
    }

    public func request<T: Decodable>(with parameters: Parameters) -> ResultCallback<T, Error> {
        return requestDecodable(T.self, with: parameters)
    }

    // MARK - Image
    public func requestImage(with parameters: Parameters) -> ResultCallback<UIImage, Error> {
        return requestCustomDecodable(ImageContent<Error>.self, with: parameters)
    }

    public func requestOptionalImage(with parameters: Parameters) -> ResultCallback<UIImage?, Error> {
        return requestCustomDecodable(OptionalImageContent<Error>.self, with: parameters)
    }

    // MARK - Data
    public func requestData(with parameters: Parameters) -> ResultCallback<Data, Error> {
        return requestCustomDecodable(DataContent<Error>.self, with: parameters)
    }

    public func requestOptionalData(with parameters: Parameters) -> ResultCallback<Data?, Error> {
        return requestCustomDecodable(OptionalDataContent<Error>.self, with: parameters)
    }

    // MARK - Any/JSON
    public func requestAny(with parameters: Parameters) -> ResultCallback<Any, Error> {
        return requestCustomDecodable(JSONContent<Error>.self, with: parameters)
    }

    public func requestOptionalAny(with parameters: Parameters) -> ResultCallback<Any?, Error> {
        return requestCustomDecodable(OptionalJSONContent<Error>.self, with: parameters)
    }
}
