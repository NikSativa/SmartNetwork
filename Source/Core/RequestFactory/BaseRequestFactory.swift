import Foundation
import UIKit
import NCallback

final
private class UnfairLock {
    private var unfairLock = os_unfair_lock_s()

    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
}

final
public class BaseRequestFactory<Error: AnyError> {
    private enum State {
        case idle
        case refreshing
    }

    private typealias Key = ObjectIdentifier

    private let pluginProvider: PluginProvider?
    private let refreshToken: AnyRefreshToken<Error>?

    typealias ScheduledRequest = () -> Void
    private let scheduledRequestsLock = UnfairLock()
    private var scheduledRequests: [Key: ScheduledRequest] = [:]

    private let stateLock = UnfairLock()
    private var state: State = .idle
    
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
        stateLock.lock()
        state = .idle
        stateLock.unlock()

        scheduledRequestsLock.lock()
        scheduledRequests.values.forEach {
            $0()
        }
        scheduledRequestsLock.unlock()
    }

    private func refresh<T>(refreshToken: AnyRefreshToken<Error>,
                            actual: ResultCallback<T, Error>) {
        stateLock.lock()
        if state == .refreshing {
            stateLock.unlock()
            return
        }
        state = .refreshing
        stateLock.unlock()

        let factoryWithoutRefreshToken = Self(pluginProvider: pluginProvider)
        refreshToken.makeRequest(factoryWithoutRefreshToken).onComplete { [weak self] in
            self?.unfreeze()
        }
    }

    private func check<T>(actual: ResultCallback<T, Error>,
                          result: Result<T, Error>) {
        switch result {
        case .success:
            scheduledRequestsLock.lock()
            scheduledRequests[Key(actual)] = nil
            scheduledRequestsLock.unlock()

            actual.complete(result)
        case .failure(let error):
            if let refreshToken = refreshToken, refreshToken.shouldRefresh(error) {
                refresh(refreshToken: refreshToken, actual: actual)
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
                self?.scheduledRequestsLock.lock()
                self?.scheduledRequests[Key(actual)] = {
                    request.start()
                }
                self?.scheduledRequestsLock.unlock()

                self?.stateLock.lock()
                let state = self?.state ?? .idle
                self?.stateLock.unlock()

                if state == .idle {
                    request.start()
                }
            }

            stop = { [weak self] actual in
                self?.scheduledRequestsLock.lock()
                self?.scheduledRequests[Key(actual)] = nil
                self?.scheduledRequestsLock.unlock()

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
