import Foundation
import Threading

/// The ``SmartRequestManager`` class in Swift serves as a crucial component within the system,
/// managing various aspects related to requests efficiently.
/// It encompasses functionalities such as handling request states, maintaining task queues,
/// and managing request attempts. Additionally, the class incorporates plugins and
/// mechanisms for stopping request processing..
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

    /// Initializes a new instance of the ``SmartRequestManager`` class with the specified plugins, stopTheLine.
    ///
    /// - Parameters:
    ///  - plugins: The plugins to be used in the request manager for each request.
    ///  - stopTheLine: The stopTheLine mechanism to be used in the request manager for each request.
    public required init(withPlugins plugins: [Plugin] = [],
                         stopTheLine: StopTheLine? = nil) {
        self.plugins = plugins
        self.stopTheLine = stopTheLine
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
                              stopTheLine: StopTheLine? = nil) -> RequestManager {
        return Self(withPlugins: plugins,
                    stopTheLine: stopTheLine)
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
        let infos = $state.mutate { state in
            state.isRunning = true
            return state.tasksQueue.values
        }

        for info in infos {
            if !prepareRequest(info: info).tryStart() {
                removeRequestIfNeeded(for: info.key)
            }
        }
    }

    func makeStopTheLineAction(stopTheLine: StopTheLine,
                               info: Info,
                               data: RequestResult) {
        let newFactory = Self(withPlugins: plugins, stopTheLine: nil)
        stopTheLine.action(with: newFactory,
                           originalParameters: info.originalParameters,
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
        let plugins = info.plugins

        do {
            for plugin in plugins {
                try plugin.verify(data: result, userInfo: userInfo)
            }
        } catch {
            result.set(error: error)
        }
    }

    func checkStopTheLine(_ result: RequestResult, info: Info) -> Bool {
        guard let stopTheLine, !info.requestParameters.shouldIgnoreStopTheLine else {
            return true
        }

        let verificationResult = stopTheLine.verify(response: result,
                                                    for: info.requestParameters,
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
            if !prepareRequest(info: info).tryStart() {
                removeRequestIfNeeded(for: info.key)
            }
            return false
        }
    }

    func tryComplete(with result: RequestResult, for info: Info) {
        checkResult(result, info: info)

        guard checkStopTheLine(result, info: info) else {
            return
        }

        complete(with: result, for: info)
    }

    func removeRequestIfNeeded(for key: Key) {
        $state.mutate {
            $0.tasksQueue[key] = nil
        }
    }

    func complete(with result: RequestResult, for info: Info) {
        removeRequestIfNeeded(for: info.key)

        let completion = info.completion
        let userInfo = info.userInfo
        let plugins = info.plugins
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
                       parameters originalParameters: Parameters,
                       completionQueue: DelayedQueue,
                       completion: @escaping RequestManager.ResponseClosure) -> SmartTasking {
        let parameters = prepare(originalParameters)
        do {
            let request = try createRequest(address: address,
                                            parameters: parameters,
                                            userInfo: parameters.userInfo)
            let info: Info = .init(originalParameters: originalParameters,
                                   request: request) { result, userInfo, plugins in
                for plugin in plugins {
                    plugin.didFinish(withData: result, userInfo: userInfo)
                }

                completionQueue.unFire {
                    completion(result)
                }
            }
            let key = info.key

            prepareRequest(info: info)

            let shouldIgnoreStopTheLine = parameters.shouldIgnoreStopTheLine
            return SmartTask(runAction: { [weak self, request, state, key] in
                if state.isRunning || shouldIgnoreStopTheLine {
                    if !request.tryStart() {
                        self?.removeRequestIfNeeded(for: key)
                    }
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

    @discardableResult
    func prepareRequest(info: Info) -> Request {
        let key = info.key
        let request = info.request

        $state.mutate {
            $0.tasksQueue[info.key] = info
        }

        // retain manager which will be released after request completion
        request.serviceClosure = { [self, key] in
            removeRequestIfNeeded(for: key)
        }

        // NOT retain manager which will be released after request completion
        request.completion = { [weak self, info] result in
            self?.tryComplete(with: result, for: info)
        }

        return request
    }
}

// MARK: - private

private extension SmartRequestManager {
    typealias ResponseClosureWithInfo = (_ result: RequestResult, _ userInfo: UserInfo, _ plugins: [Plugin]) -> Void

    struct Info {
        let key: Key
        let originalParameters: Parameters
        let request: Request
        let completion: ResponseClosureWithInfo

        var userInfo: UserInfo {
            return request.parameters.userInfo
        }

        var plugins: [Plugin] {
            return request.parameters.plugins
        }

        var requestParameters: Parameters {
            return request.parameters
        }

        init(originalParameters: Parameters,
             request: Request,
             completion: @escaping ResponseClosureWithInfo) {
            self.key = Key()
            self.request = request
            self.originalParameters = originalParameters
            self.completion = completion
        }
    }

    final class State {
        var isRunning: Bool = true
        var tasksQueue: [Key: Info] = [:]
    }

    final class Key: Hashable {
        private let uuid: UUID = .init()

        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
        }

        static func ==(lhs: Key, rhs: Key) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }
}

#if swift(>=6.0)
extension SmartRequestManager: @unchecked Sendable {}
extension SmartRequestManager.Info: @unchecked Sendable {}
extension SmartRequestManager.State: @unchecked Sendable {}
extension SmartRequestManager.Key: Sendable {}
#endif
