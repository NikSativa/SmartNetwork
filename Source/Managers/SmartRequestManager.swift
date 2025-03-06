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
/// See detailed scheme of network request management:
/// ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
///
/// - Important: This is a real request manager.
public final class SmartRequestManager {
    private var isRunning: Bool = true
    private let plugins: [Plugin]
    private let session: SmartURLSession
    private let stopTheLine: StopTheLine?
    private let retrier: SmartRetrier?

    /// Initializes a new instance of the ``SmartRequestManager`` class with the specified plugins, stopTheLine.
    ///
    /// - Parameters:
    ///  - plugins: The ``Plugin`` to be used in the request manager for each request. Default is `[]`.
    ///  - stopTheLine: The ``StopTheLine`` mechanism to be used in the request manager for each request. Default is `nil`.
    ///  - retrier: The ``SmartRetrier`` mechanism to be used in the request manager for each request. Default is `nil`.
    ///  - session: The ``SmartURLSession`` to be used in the request manager for each request. Default is `RequestSettings.sharedSession`.
    public required init(withPlugins plugins: [Plugin] = [],
                         stopTheLine: StopTheLine? = nil,
                         retrier: SmartRetrier? = nil,
                         session: SmartURLSession = SmartNetworkSettings.sharedSession) {
        self.plugins = plugins
        self.stopTheLine = stopTheLine
        self.retrier = retrier
        self.session = session
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
    ///
    /// - Parameters:
    ///  - plugins: The ``Plugin`` to be used in the request manager for each request. Default is `[]`.
    ///  - stopTheLine: The ``StopTheLine`` mechanism to be used in the request manager for each request. Default is `nil`.
    ///  - retrier: The ``SmartRetrier`` mechanism to be used in the request manager for each request. Default is `nil`.
    ///  - session: The ``SmartURLSession`` to be used in the request manager for each request. Default is `RequestSettings.sharedSession`.
    ///  - Returns: A new instance of the ``RequestManager`` protocol.
    public static func create(withPlugins plugins: [Plugin] = [],
                              stopTheLine: StopTheLine? = nil,
                              retrier: SmartRetrier? = nil,
                              session: SmartURLSession = SmartNetworkSettings.sharedSession) -> RequestManager {
        return Self(withPlugins: plugins,
                    stopTheLine: stopTheLine,
                    retrier: retrier,
                    session: session)
    }
}

// MARK: - RequestManager

extension SmartRequestManager: RequestManager {
    public func request(address: Address, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse {
        return await startRequest(address: address, parameters: parameters, userInfo: userInfo)
    }

    /// Sends a request to the specified address with the given parameters.
    public func request(address: Address,
                        parameters: Parameters = .init(),
                        userInfo: UserInfo = .init(),
                        completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                        completion: @escaping ResponseClosure) -> SmartTasking {
        let task = Task.detached {
            return await self.request(address: address, parameters: parameters, userInfo: userInfo)
        }
        return SmartTask {
            let unsendable = USendable(completion)
            Task.detached { [unsendable] in
                let data = await task.value
                do {
                    try data.checkCancellation()
                    completionQueue.fire {
                        unsendable.value(data)
                    }
                } catch {
                    // nothing to do. request was cancelled.
                }
            }
        } cancelAction: {
            task.cancel()
        }
        .fillUserInfo(with: address)
    }
}

private extension SmartRequestManager {
    func startRequest(address: Address, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse {
        func retryAction() async -> SmartResponse {
            return await startRequest(address: address, parameters: parameters, userInfo: userInfo)
        }

        do {
            try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
        } catch {
            // if the `Task.sleep` is cancelled before the time ends.
            return .init(error: error, session: session)
        }

        let parameters = prepare(parameters)

        var data: SmartResponse
        do {
            let request = try await createRequest(address: address, parameters: parameters, userInfo: userInfo)

            try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
            data = await request.start()
        } catch {
            data = .init(error: error, session: session)
        }

        do {
            for plugin in parameters.plugins {
                try plugin.verify(parameters: parameters, userInfo: userInfo, data: data)
            }
        } catch {
            // In the event that the request already has an error, and the plugin throws a new one,
            // then we must reduce the existing one, because the error from the `Plugin` is more priority for the application
            data.set(error: error)
        }

        if await shouldRetry(data, address: address, parameters: parameters, userInfo: userInfo) {
            return await retryAction()
        }

        do {
            assert(!Thread.isMainThread)
            let stopTheLineResult = try await checkStopTheLine(data, address: address, parameters: parameters, userInfo: userInfo)
            switch stopTheLineResult {
            case .useOriginal:
                break
            case .passOver(let newResponse):
                data = newResponse
            case .retry:
                return await retryAction()
            case .retryWithDelay(let delay):
                try await Task.sleep(seconds: delay)
                return await retryAction()
            }
        } catch {
            // In the event that the request already has an error, and the plugin throws a new one,
            // then we must reduce the existing one, because the error from the `StopTheLine` is more priority for the application
            data.set(error: error)
        }

        for plugin in parameters.plugins {
            plugin.didFinish(parameters: parameters, userInfo: userInfo, data: data)
        }

        return data
    }

    func waitUntilRunning(_ shouldIgnoreStopTheLine: Bool) async throws {
        if shouldIgnoreStopTheLine {
            return
        }

        while !isRunning {
            try await Task.sleep(seconds: 0.1)
        }
    }

    func prepare(_ parameters: Parameters) -> Parameters {
        var parameters = parameters

        let newPlugins = (parameters.plugins + plugins).prepareForExecution()
        parameters.plugins = newPlugins
        return parameters
    }

    func createRequest(address: Address, parameters: Parameters, userInfo: UserInfo) async throws -> SmartRequest {
        var urlRequest = try parameters.urlRequest(for: address)
        for plugin in parameters.plugins {
            await plugin.prepare(parameters: parameters, userInfo: userInfo, request: &urlRequest, session: session)
        }

        let request = SmartRequest(address: address,
                                   parameters: parameters,
                                   userInfo: userInfo,
                                   urlRequestable: urlRequest,
                                   session: session)
        return request
    }

    @MainActor
    func checkStopTheLine(_ result: SmartResponse,
                          address: Address,
                          parameters: Parameters,
                          userInfo: UserInfo) async throws -> StopTheLineResult {
        assert(Thread.isMainThread)

        guard let stopTheLine, !parameters.shouldIgnoreStopTheLine else {
            return .passOver(result)
        }

        let verificationResult = stopTheLine.verify(response: result,
                                                    address: address,
                                                    parameters: parameters,
                                                    userInfo: userInfo)
        switch verificationResult {
        case .stopTheLine:
            isRunning = false
            let newFactory = Self(withPlugins: plugins, stopTheLine: nil, retrier: retrier)
            do {
                let result = try await stopTheLine.action(with: newFactory,
                                                          response: result,
                                                          address: address,
                                                          parameters: parameters,
                                                          userInfo: userInfo)
                isRunning = true
                return result
            } catch {
                isRunning = true
                throw error
            }
        case .passOver:
            return .passOver(result)
        case .retry:
            return .retry
        }
    }

    func shouldRetry(_ data: SmartResponse, address: Address, parameters: Parameters, userInfo: UserInfo) async -> Bool {
        let retryOrFinish = retrier?.retryOrFinish(result: data, address: address, parameters: parameters, userInfo: userInfo)
        defer {
            userInfo.attemptsCount += 1
        }

        do {
            switch retryOrFinish ?? .doNotRetry {
            case .retry:
                return true
            case .retryWithDelay(let delay):
                try await Task.sleep(seconds: delay)
                return true
            case .doNotRetry:
                return false
            case .doNotRetryWithError(let error):
                data.set(error: error)
                return false
            }
        } catch {
            // if the `Task.sleep` is cancelled before the time ends.
            data.set(error: error)
            return false
        }
    }
}

private extension SmartTask {
    func fillUserInfo(with address: Address) -> Self {
        userInfo.smartRequestAddress = address
        return self
    }
}

private extension SmartResponse {
    convenience init(error: Error, session: SmartURLSession) {
        self.init(request: nil, body: nil, response: nil, error: error, session: session)
    }
}

#if swift(>=6.0)
extension SmartRequestManager: @unchecked Sendable {}
#endif
