import Foundation
import NCallback
import NQueue

extension Impl {
    final class RequestManager<Error: AnyError> {
        private typealias Request = NRequest.Request

        private enum State {
            case idle
            case stopped
        }

        private typealias Key = ObjectIdentifier

        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var state: State = .idle

        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var scheduledRequests: [Key: Request] = [:]
        private var scheduledParameters: [Key: Parameters] = [:]

        private let pluginProvider: PluginProvider?
        private let stopTheLine: AnyStopTheLine<Error>?
        private let factory: NRequest.RequestFactory

        init(factory: NRequest.RequestFactory,
             pluginProvider: PluginProvider?,
             stopTheLine: AnyStopTheLine<Error>?) {
            self.factory = factory
            self.pluginProvider = pluginProvider
            self.stopTheLine = stopTheLine
        }

        private func unfreeze() {
            state = .idle

            let scheduledRequests = self.scheduledRequests
            for request in scheduledRequests {
                request.value.restartIfNeeded()
            }
        }

        private func makeStopTheLineAction(actual: Callback<ResponseData>,
                                           refreshToken: AnyStopTheLine<Error>,
                                           request: Request,
                                           data: ResponseData,
                                           key: Key) {
            if state == .stopped {
                return
            }
            state = .stopped

            let stopTheLineFactory = Self(factory: factory,
                                          pluginProvider: pluginProvider,
                                          stopTheLine: nil).toAny()
            refreshToken.action(with: stopTheLineFactory,
                                originalParameters: request.parameters,
                                response: data).onComplete { [weak self] result in
                switch result {
                case .useOriginal:
                    self?.removeFromCache(key)
                    actual.complete(data)
                case .passOver(let newResponse):
                    self?.removeFromCache(key)
                    actual.complete(newResponse)
                case .retry:
                    break
                }
                self?.unfreeze()
            }
        }

        private func removeFromCache(_ key: Key) {
            $scheduledRequests.mutate {
                $0[key] = nil
            }
        }

        private func checkStopTheLine(actual: Callback<ResponseData>,
                                      request: Request,
                                      result: ResponseData,
                                      key: Key) {
            if let stopTheLine = stopTheLine {
                let scheduledRequest = $scheduledRequests.mutate {
                    return $0[key]
                }

                if let scheduledRequest = scheduledRequest {
                    let verificationResult = stopTheLine.verify(response: result,
                                                                for: request.parameters)
                    switch verificationResult {
                    case .passOver:
                        removeFromCache(key)
                        actual.complete(result)
                    case .retry:
                        scheduledRequest.restartIfNeeded()
                    case .stopTheLine:
                        makeStopTheLineAction(actual: actual,
                                              refreshToken: stopTheLine,
                                              request: scheduledRequest,
                                              data: result,
                                              key: key)
                    }
                } else {
                    actual.complete(result)
                }
            } else {
                actual.complete(result)
            }
        }

        private func prepare(_ request: Request) -> Callback<ResponseData> {
            typealias ServiceClosure = Callback<ResponseData>.ServiceClosure

            let start: ServiceClosure
            let stop: ServiceClosure
            let key = Key(request)

            if let _ = stopTheLine {
                start = { [weak self] actual in
                    if let self = self {
                        self.$scheduledRequests.mutate {
                            $0[key] = request
                        }

                        if self.state == .idle {
                            request.start { [weak self] data in
                                if let self = self {
                                    self.checkStopTheLine(actual: actual,
                                                          request: request,
                                                          result: data,
                                                          key: key)
                                } else {
                                    actual.complete(data)
                                }
                            }
                        }
                    } else {
                        request.start { data in
                            actual.complete(data)
                        }
                    }
                }

                stop = { [weak self] _ in
                    self?.removeFromCache(key)
                    request.cancel()
                }
            } else {
                start = { actual in
                    request.start { data in
                        actual.complete(data)
                    }
                }

                stop = { _ in
                    request.cancel()
                }
            }

            return .init(start: start,
                         stop: stop)
        }
    }
}

extension Impl.RequestManager: RequestManager {
    func requestPureData(with parameters: Parameters) -> Callback<ResponseData> {
        let request: Request = factory.make(for: parameters,
                                            pluginContext: pluginProvider)
        return prepare(request).beforeComplete { [pluginProvider] data in
            for plugin in pluginProvider?.plugins() ?? [] {
                plugin.didFinish(parameters,
                                 data: data,
                                 dto: nil)
            }
        }
    }

    func requestCustomDecodable<T: CustomDecodable>(_: T.Type,
                                                    with parameters: Parameters) -> ResultCallback<T.Object, Error> {
        let request: Request = factory.make(for: parameters,
                                            pluginContext: pluginProvider)
        return prepare(request).flatMap { [pluginProvider] data in
            let payload = T(with: data)
            let result = payload.result.mapError(Error.wrap)

            switch result {
            case .success:
                data.error = nil
            case .failure(let error):
                data.error = error
            }

            for plugin in pluginProvider?.plugins() ?? [] {
                plugin.didFinish(parameters,
                                 data: data,
                                 dto: try? result.get())
            }
            return result
        }
    }
}
