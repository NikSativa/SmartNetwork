import Foundation
import Threading

/// Manages the orchestration and lifecycle of network requests within SmartNetwork.
///
/// `SmartRequestManager` handles request creation, plugin execution, retry logic, cancellation,
/// and the `StopTheLine` mechanism. It ensures reliable and testable execution of HTTP workflows,
/// and supports both async and callback-based request interfaces.
public final class SmartRequestManager {
    private var isRunning: Bool = true
    private let plugins: [Plugin]
    private let session: SmartURLSession
    private let stopTheLine: StopTheLine?
    private let retrier: SmartRetrier?

    /// Initializes a new instance of `SmartRequestManager`.
    ///
    /// - Parameters:
    ///   - plugins: Plugins to be applied to each request (e.g., logging, auth).
    ///   - stopTheLine: Mechanism for interrupting or retrying request flow based on results.
    ///   - retrier: Logic for retrying failed requests based on response or error.
    ///   - session: Custom session implementation (defaults to `SmartNetworkSettings.sharedSession`).
    public required init(withPlugins plugins: [Plugin] = [],
                         stopTheLine: StopTheLine? = nil,
                         retrier: SmartRetrier? = nil,
                         session: SmartURLSession = SmartNetworkSettings.sharedSession) {
        self.plugins = plugins
        self.stopTheLine = stopTheLine
        self.retrier = retrier
        self.session = session
    }

    /// Convenience factory for protocol-based instantiation and testability.
    ///
    /// - Returns: A new instance conforming to `RequestManager`.
    /// - SeeAlso: Useful for mocking request management logic in unit tests.
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

    /// Sends a request with callback-based completion handling.
    ///
    /// - Parameters:
    ///   - address: The target endpoint.
    ///   - parameters: Request configuration.
    ///   - userInfo: Contextual metadata for the request.
    ///   - completionQueue: Queue on which to deliver the final result.
    ///   - completion: A closure called with the `SmartResponse`.
    /// - Returns: A cancellable task handle.
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
    /// Executes the request pipeline including plugins, retry logic, and `StopTheLine` handling.
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
            try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
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
            try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
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

    /// Suspends execution until the manager is running, unless bypass is specified.
    func waitUntilRunning(_ shouldIgnoreStopTheLine: Bool) async throws {
        if shouldIgnoreStopTheLine {
            return
        }

        while !isRunning {
            try await Task.sleep(seconds: 0.1)
        }
    }

    /// Merges and prepares plugins for the current request context.
    func prepare(_ parameters: Parameters) -> Parameters {
        var parameters = parameters

        let newPlugins = (parameters.plugins + plugins).prepareForExecution()
        parameters.plugins = newPlugins
        return parameters
    }

    /// Constructs and configures a `SmartRequest` including plugin preparation.
    ///
    /// - Throws: An error if the URLRequest cannot be created.
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

    /// Evaluates whether request flow should continue, retry, or halt based on response and `StopTheLine` logic.
    ///
    /// - Returns: A `StopTheLineResult` controlling how the pipeline proceeds.
    /// - Throws: Any error surfaced by the stop handler.
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

    /// Determines if a failed request should be retried based on the retrier's evaluation.
    ///
    /// - Returns: `true` if a retry should occur; otherwise `false`.
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
    /// Associates the request address with the userInfo metadata.
    func fillUserInfo(with address: Address) -> Self {
        userInfo.smartRequestAddress = address
        return self
    }
}

private extension SmartResponse {
    /// Creates a `SmartResponse` from an error and session context.
    convenience init(error: Error, session: SmartURLSession) {
        self.init(request: nil, body: nil, response: nil, error: error, session: session)
    }
}

#if swift(>=6.0)
extension SmartRequestManager: @unchecked Sendable {}
#endif
