import Foundation
import NQueue

extension Impl {
    private typealias Key = ObjectIdentifier
    private typealias ResponseClosure = (ResponseData) -> Void

    private final class Info {
        let key: Key
        let parameters: Parameters
        let request: Requestable
        let completion: ResponseClosure
        var attemptNumber: UInt

        init(parameters: Parameters,
             request: Requestable,
             completion: @escaping ResponseClosure) {
            self.key = Key(request)
            self.parameters = parameters
            self.request = request
            self.completion = completion
            self.attemptNumber = 0
        }
    }

    private final class State {
        var isRunning: Bool = true
        var queue: [Key: Info] = [:]
    }

    final class RequestManager {
        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var state: State = .init()
        private let pluginProvider: PluginProvider?
        private let stopTheLine: StopTheLine?
        private let maxAttemptNumber: UInt

        init(pluginProvider: PluginProvider?,
             stopTheLine: StopTheLine?,
             maxAttemptNumber: UInt = 1) {
            self.pluginProvider = pluginProvider
            self.stopTheLine = stopTheLine
            self.maxAttemptNumber = max(maxAttemptNumber, 1)
        }

        private func unfreeze() {
            $state.mutate { state in
                state.isRunning = true

                let scheduledRequests = state.queue
                for request in scheduledRequests {
                    request.value.request.start()
                }
            }
        }

        private func makeStopTheLineAction(stopTheLine: StopTheLine,
                                           info: Info,
                                           data: ResponseData) {
            Task { [weak self, pluginProvider, maxAttemptNumber] in
                let newFactory = RequestManager(pluginProvider: pluginProvider,
                                                stopTheLine: nil,
                                                maxAttemptNumber: maxAttemptNumber)
                let result = await stopTheLine.action(with: newFactory,
                                                      originalParameters: info.request.parameters,
                                                      response: data,
                                                      userInfo: &info.request.userInfo)
                switch result {
                case .useOriginal:
                    tryComplete(with: data, for: info)
                case .passOver(let newResponse):
                    tryComplete(with: newResponse, for: info)
                case .retry:
                    break
                }
                self?.unfreeze()
            }
        }

        private func checkStopTheLine(_ result: ResponseData,
                                      info: Info) -> Bool {
            guard let stopTheLine else {
                return true
            }

            let verificationResult = stopTheLine.verify(response: result,
                                                        for: info.parameters,
                                                        userInfo: &info.request.userInfo)
            switch verificationResult {
            case .stopTheLine:
                if state.isRunning {
                    state.isRunning = false
                }
                makeStopTheLineAction(stopTheLine: stopTheLine,
                                      info: info,
                                      data: result)
                return false
            case .passOver:
                return true
            case .retry:
                if info.attemptNumber < maxAttemptNumber {
                    info.attemptNumber += 1
                    info.request.start()
                }
                return false
            }
        }

        private func tryComplete(with result: ResponseData,
                                 for info: Info) {
            guard checkStopTheLine(result, info: info) else {
                return
            }

            do {
                let userInfo = info.request.userInfo
                for plugin in pluginProvider?.plugins() ?? [] {
                    try plugin.verify(data: result, userInfo: userInfo)
                }
            } catch {
                result.set(error)
            }

            state.queue[info.key] = nil

            let completion = info.completion
            info.parameters.queue.fire {
                completion(result)
            }
        }

        private func createRequest(_ parameters: Parameters,
                                   userInfo: inout Parameters.UserInfo) throws -> Requestable {
            let sdkRequest = try parameters.sdkRequest()
            var urlRequestable: NRequest.URLRequestWrapper = Impl.URLRequestWrapper(sdkRequest)

            for plugin in pluginProvider?.plugins() ?? [] {
                plugin.prepare(parameters,
                               request: &urlRequestable,
                               userInfo: &userInfo)
            }

            let request = Request.create(with: parameters,
                                         urlRequestable: urlRequestable,
                                         userInfo: userInfo)
            return request
        }

        private func request(with parameters: Parameters,
                             userInfo: inout Parameters.UserInfo,
                             completion: @escaping ResponseClosure) throws {
            let request = try self.createRequest(parameters, userInfo: &userInfo)
            let info: Info = .init(parameters: parameters,
                                   request: request,
                                   completion: completion)
            state.queue[info.key] = info

            request.completion = { [weak self, unowned info] result in
                self?.tryComplete(with: result, for: info)
            }

            if state.isRunning {
                request.start()
            }
        }
    }
}

// MARK: - Impl.RequestManager + RequestManager

extension Impl.RequestManager: RequestManager {
//        func requestCustomDecodable<T: CustomDecodable>(_: T.Type,
//                                                        with parameters: Parameters) -> ResultCallback<T.Object, Error> {
//            let request: Request = factory.make(for: parameters,
//                                                pluginContext: pluginProvider)
//            return prepare(request).flatMap { [pluginProvider] data in
//                let payload = T(with: data)
//                let result = payload.result.mapError(Error.wrap)
//
//                switch result {
//                case .success:
//                    data.error = nil
//                case .failure(let error):
//                    data.error = error
//                }
//
//                for plugin in pluginProvider?.plugins() ?? [] {
//                    plugin.didFinish(parameters,
//                                     data: data,
//                                     userInfo: &request.userInfo,
//                                     dto: try? result.get())
//                }
//                return result
//            }
//        }
}

private extension Parameters {
    func sdkRequest() throws -> URLRequest {
        let url = try address.url(shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint)
        var request = URLRequest(url: url,
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method.toString()

        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }

        try body.fill(&request, isLoggingEnabled: isLoggingEnabled, encoder: encoder)

        return request
    }
}
