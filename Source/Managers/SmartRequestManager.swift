import Foundation
import Threading

/// The ``SmartRequestManager`` class in Swift serves as a crucial component within the system,
/// managing various aspects related to requests efficiently.
/// It encompasses functionalities such as handling request states, maintaining task queues,
/// and managing request attempts. Additionally, the class incorporates plugins,
/// mechanisms for stopping request processing,
/// and parameters for controlling the maximum number of request attempts.
/// The ``SmartRequestManager`` class plays a pivotal role in orchestrating and
/// executing request-related tasks within the system,
/// ensuring streamlined and organized request management.
///
/// - Important: This is a real request manager.
public final class SmartRequestManager {
    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var state: State = .init()
    private let plugins: [Plugin]
    private let stopTheLine: StopTheLine?
    private let maxAttemptNumber: Int

    /// Initializes a new instance of the ``SmartRequestManager`` class with the specified plugins, stopTheLine, and maxAttemptNumber.
    public required init(withPlugins plugins: [Plugin] = [],
                         stopTheLine: StopTheLine? = nil,
                         maxAttemptNumber: Int = 1) {
        self.plugins = plugins
        self.stopTheLine = stopTheLine
        self.maxAttemptNumber = max(maxAttemptNumber, 1)
    }

    /// Creates protocol wrapped interface instead of concrete realization
    ///
    /// ```swift
    /// let manager: RequestManager = SmartRequestManager()
    /// ```
    /// vs
    /// ```swift
    /// let manager = SmartRequestManager.create()
    /// ```
    ///
    /// - Tip: The protocol is useful for mocking and testing request management functionalities in Swift.
    public static func create(withPlugins plugins: [Plugin] = [],
                              stopTheLine: StopTheLine? = nil,
                              maxAttemptNumber: Int = 1) -> RequestManager {
        return Self(withPlugins: plugins,
                    stopTheLine: stopTheLine,
                    maxAttemptNumber: maxAttemptNumber)
    }
}

// MARK: - RequestManager

extension SmartRequestManager: RequestManager {
    public func request(address: Address,
                        parameters: Parameters,
                        completionQueue: DelayedQueue,
                        completion: @escaping ResponseClosure) -> SmartTasking {
        // internal to make protocol conformans small
        return createRequest(address: address,
                             parameters: parameters,
                             completionQueue: completionQueue,
                             completion: completion)
    }
}

private extension SmartRequestManager {
    func unfreeze() {
        let scheduledRequests = $state.mutate { state in
            state.isRunning = true
            return state.tasksQueue
        }

        for request in scheduledRequests {
            request.value.request.restart()
        }
    }

    func makeStopTheLineAction(stopTheLine: StopTheLine,
                               info: Info,
                               data: RequestResult) {
        let newFactory = Self(withPlugins: plugins,
                              stopTheLine: nil,
                              maxAttemptNumber: maxAttemptNumber)
        stopTheLine.action(with: newFactory,
                           originalParameters: info.request.parameters,
                           response: data,
                           userInfo: info.userInfo) { [self] result in
            switch result {
            case .useOriginal:
                complete(with: data, for: info)
            case .passOver(let newResponse):
                complete(with: newResponse, for: info)
            case .retry:
                break
            }
            unfreeze()
        }
    }

    func checkResult(_ result: RequestResult, info: Info) {
        let userInfo = info.userInfo
        let plugins = info.parameters.plugins

        do {
            for plugin in plugins {
                try plugin.verify(data: result, userInfo: userInfo)
            }
        } catch {
            result.set(error: error)
        }
    }

    func checkStopTheLine(_ result: RequestResult, info: Info) -> Bool {
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
                info.request.restart()
                return false
            }
            return true
        }
    }

    func tryComplete(with result: RequestResult, for info: Info) {
        checkResult(result, info: info)

        guard checkStopTheLine(result, info: info) else {
            return
        }

        complete(with: result, for: info)
    }

    func removeRequestIfNeeded(for info: Info) {
        $state.mutate {
            $0.tasksQueue[info.key] = nil
        }
    }

    func complete(with result: RequestResult, for info: Info) {
        removeRequestIfNeeded(for: info)

        let completion = info.completion
        let userInfo = info.userInfo
        let plugins = info.parameters.plugins
        completion(result, userInfo, plugins)
    }

    func createRequest(address: Address,
                       parameters: Parameters,
                       userInfo: UserInfo) throws -> Request {
        var urlRequest = try parameters.urlRequest(for: address)
        for plugin in parameters.plugins {
            plugin.prepare(parameters,
                           request: &urlRequest)
        }

        let request = Request(address: address,
                              parameters: parameters,
                              urlRequestable: urlRequest)
        return request
    }

    func prepare(_ parameters: Parameters) -> Parameters {
        let newPlugins: [Plugin]
        if plugins.isEmpty {
            newPlugins = parameters.plugins
        } else {
            var plugins = parameters.plugins
            plugins += self.plugins
            newPlugins = plugins
        }

        var newParameters = parameters
        newParameters.plugins = newPlugins
            .unified()
            .sorted { a, b in
                return a.priority > b.priority
            }
        return newParameters
    }

    func createRequest(address: Address,
                       parameters: Parameters,
                       completionQueue: DelayedQueue,
                       completion: @escaping RequestManager.ResponseClosure) -> SmartTasking {
        let parameters = prepare(parameters)
        do {
            let request = try createRequest(address: address,
                                            parameters: parameters,
                                            userInfo: parameters.userInfo)
            let info: Info = .init(parameters: parameters,
                                   request: request) { result, userInfo, plugins in
                for plugin in plugins {
                    plugin.didFinish(withData: result, userInfo: userInfo)
                }

                completionQueue.unFire {
                    completion(result)
                }
            }

            $state.mutate {
                $0.tasksQueue[info.key] = info
            }

            request.serviceCompletion = { [weak self, weak info] in
                if let self, let info {
                    removeRequestIfNeeded(for: info)
                }
            }

            request.completion = { [weak self, weak info] result in
                if let self, let info {
                    tryComplete(with: result, for: info)
                }
            }

            return SmartTask(runAction: { [state] in
                if state.isRunning {
                    request.start()
                }
            }, cancelAction: { [request] in
                request.cancel()
            })
            .fillUserInfo(with: address)
        } catch {
            return SmartTask(runAction: {
                let result = RequestResult(request: nil, body: nil, response: nil, error: error)
                completion(result)
            })
            .fillUserInfo(with: address)
        }
    }
}

// MARK: - private

private extension SmartRequestManager {
    typealias Key = ObjectIdentifier
    #if swift(>=6.0)
    typealias ResponseClosureWithInfo = (_ result: RequestResult, _ userInfo: UserInfo, _ plugins: [Plugin]) -> Void
    #else
    typealias ResponseClosureWithInfo = (_ result: RequestResult, _ userInfo: UserInfo, _ plugins: [Plugin]) -> Void
    #endif

    final class Info {
        let key: Key
        let parameters: Parameters
        let request: Request
        let completion: ResponseClosureWithInfo
        #if swift(>=6.0)
        nonisolated(unsafe) var attemptNumber: Int
        #else
        var attemptNumber: Int
        #endif

        var userInfo: UserInfo {
            return parameters.userInfo
        }

        init(parameters: Parameters,
             request: Request,
             completion: @escaping ResponseClosureWithInfo) {
            self.key = Key(request)
            self.parameters = parameters
            self.request = request
            self.completion = completion
            self.attemptNumber = 0
        }
    }

    struct State {
        var isRunning: Bool = true
        var tasksQueue: [Key: Info] = [:]
    }
}

#if swift(>=6.0)
extension SmartRequestManager: @unchecked Sendable {}
extension SmartRequestManager.Info: @unchecked Sendable {}
extension SmartRequestManager.State: Sendable {}
#endif
