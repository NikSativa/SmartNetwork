import Foundation
import NQueue

public final class RequestManager {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var state: State = .init()
    private let pluginProvider: PluginProviding?
    private let stopTheLine: StopTheLine?
    private let maxAttemptNumber: UInt

    private init(pluginProvider: PluginProviding?,
                 stopTheLine: StopTheLine?,
                 maxAttemptNumber: UInt) {
        self.pluginProvider = pluginProvider
        self.stopTheLine = stopTheLine
        self.maxAttemptNumber = max(maxAttemptNumber, 1)
    }

    public static func create(withPluginProvider pluginProvider: PluginProviding? = nil,
                              stopTheLine: StopTheLine? = nil,
                              maxAttemptNumber: UInt = 1) -> RequestManagering {
        return Self(pluginProvider: pluginProvider,
                    stopTheLine: stopTheLine,
                    maxAttemptNumber: maxAttemptNumber)
    }

    private func unfreeze() {
        $state.mutate { state in
            state.isRunning = true

            let scheduledRequests = state.tasksQueue
            for request in scheduledRequests {
                request.value.request.start()
            }
        }
    }

    private func makeStopTheLineAction(stopTheLine: StopTheLine,
                                       info: Info,
                                       data: RequestResult) {
        Task { [weak self, pluginProvider, maxAttemptNumber] in
            let newFactory = RequestManager(pluginProvider: pluginProvider,
                                            stopTheLine: nil,
                                            maxAttemptNumber: maxAttemptNumber)
            let result = await stopTheLine.action(with: newFactory,
                                                  originalParameters: info.request.parameters,
                                                  response: data,
                                                  userInfo: info.userInfo)
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

    private func checkStopTheLine(_ result: RequestResult,
                                  info: Info) -> Bool {
        guard let stopTheLine else {
            return true
        }

        let verificationResult = stopTheLine.verify(response: result,
                                                    for: info.parameters,
                                                    userInfo: info.userInfo)
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

    private func tryComplete(with result: RequestResult,
                             for info: Info) {
        guard checkStopTheLine(result, info: info) else {
            return
        }

        do {
            let userInfo = info.userInfo
            for plugin in pluginProvider?.plugins() ?? [] {
                try plugin.verify(data: result, userInfo: userInfo)
            }
        } catch {
            result.set(error)
        }

        state.tasksQueue[info.key] = nil

        let completion = info.completion
        completion(result)
    }

    private func createRequest(address: Address,
                               with parameters: Parameters,
                               inQueue completionQueue: DelayedQueue,
                               userInfo: UserInfo) throws -> Requestable {
        var urlRequest = try parameters.urlRequest(for: address)
        for plugin in pluginProvider?.plugins() ?? [] {
            plugin.prepare(parameters,
                           request: &urlRequest)
        }

        let request = Request.create(address: address,
                                     with: parameters,
                                     urlRequestable: urlRequest,
                                     completionQueue: completionQueue)
        return request
    }
}

// MARK: - RequestManagering

extension RequestManager: RequestManagering {
    public static func map<T: CustomDecodable>(data: RequestResult,
                                               to _: T.Type,
                                               with parameters: Parameters) -> Result<T.Object, Error> {
        let payload = T(with: data, decoder: parameters.decoder)
        let result = payload.result

        switch result {
        case .success:
            data.set(nil)
        case .failure(let error):
            data.set(error)
        }

        return result
    }

    public func request(address: Address,
                        with parameters: Parameters,
                        inQueue completionQueue: DelayedQueue,
                        completion: @escaping ResponseClosure) -> RequestingTask {
        do {
            let request = try createRequest(address: address,
                                            with: parameters,
                                            inQueue: completionQueue,
                                            userInfo: parameters.userInfo)
            let info: Info = .init(parameters: parameters,
                                   request: request,
                                   completion: completion)
            state.tasksQueue[info.key] = info

            request.completion = { [weak self, unowned info] result in
                self?.tryComplete(with: result, for: info)
            }

            return RequestingTask(runAction: { [state] in
                if state.isRunning {
                    request.start()
                }
            }, cancelAction: { [request] in
                request.cancel()
            })
        } catch {
            return RequestingTask(runAction: {
                let result = RequestResult(request: nil, body: nil, response: nil, error: error)
                completion(result)
            })
        }
    }
}

// MARK: - private

private extension RequestManager {
    typealias Key = ObjectIdentifier

    final class Info {
        let key: Key
        let parameters: Parameters
        let request: Requestable
        let completion: RequestManager.ResponseClosure
        var attemptNumber: UInt

        var userInfo: UserInfo {
            return parameters.userInfo
        }

        init(parameters: Parameters,
             request: Requestable,
             completion: @escaping RequestManager.ResponseClosure) {
            self.key = Key(request)
            self.parameters = parameters
            self.request = request
            self.completion = completion
            self.attemptNumber = 0
        }
    }

    final class State {
        var isRunning: Bool = true
        var tasksQueue: [Key: Info] = [:]
    }
}
