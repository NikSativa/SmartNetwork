import Foundation
import NQueue

public final class RequestManager {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var state: State = .init()
    private let pluginProvider: PluginProvider?
    private let stopTheLine: StopTheLine?
    private let maxAttemptNumber: UInt

    private init(pluginProvider: PluginProvider?,
                 stopTheLine: StopTheLine?,
                 maxAttemptNumber: UInt) {
        self.pluginProvider = pluginProvider
        self.stopTheLine = stopTheLine
        self.maxAttemptNumber = max(maxAttemptNumber, 1)
    }

    public func create(withPluginProvider pluginProvider: PluginProvider?,
                       stopTheLine: StopTheLine?,
                       maxAttemptNumber: UInt = 1) -> RequestManagering {
        return Self(pluginProvider: pluginProvider,
                    stopTheLine: stopTheLine,
                    maxAttemptNumber: maxAttemptNumber)
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
        completion(result)
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
}

// MARK: - RequestManagering

extension RequestManager: RequestManagering {
    public static func map<T: CustomDecodable>(data: ResponseData,
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

    public func request(with parameters: Parameters,
                        completion: @escaping ResponseClosure) -> LoadingTask {
        do {
            var userInfo = parameters.userInfo
            let request = try createRequest(parameters, userInfo: &userInfo)
            let info: Info = .init(parameters: parameters,
                                   request: request,
                                   completion: completion)
            state.queue[info.key] = info

            request.completion = { [weak self, unowned info] result in
                self?.tryComplete(with: result, for: info)
            }

            return LoadingTask(runAction: { [state] in
                if state.isRunning {
                    request.start()
                }
            }, cancelAction: { [request] in
                request.cancel()
            })
        } catch {
            return LoadingTask(runAction: {
                let result = ResponseData(request: nil, body: nil, response: nil, error: error)
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
        var queue: [Key: Info] = [:]
    }
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
