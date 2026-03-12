import Foundation
import Threading

/// Represents the possible outcomes of a stop-the-line resolution.
///
/// Used to determine how the system should proceed after an interruption or validation check in the request pipeline.
/// Each case defines a distinct strategy for continuing or retrying the request flow.
private enum StopTheLineQueueAction: SmartSendable {
    /// Replaces the original response with a new one and proceeds.
    ///
    /// - Parameter response: The alternative `SmartResponse` to use.
    case passOver

    /// Discards the current response and immediately retries the request.
    case retry

    /// Discards the current response and retries the request after a delay.
    ///
    /// - Parameter delay: The time interval to wait before retrying.
    case retryWithDelay(TimeInterval)
}

/// Manages the orchestration and lifecycle of network requests within SmartNetwork.
///
/// `SmartRequestManager` handles request creation, plugin execution, retry logic, cancellation,
/// and the `StopTheLine` mechanism. It ensures reliable and testable execution of HTTP workflows,
/// and supports both async and callback-based request interfaces.
public final class SmartRequestManager {
    @AtomicValue
    private var isRunning: Bool = true
    @AtomicValue
    private var lastStopTheLineQueueAction: StopTheLineQueueAction = .passOver

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

private final class RequestCompletionState: @unchecked Sendable {
    @AtomicValue
    private var networkTask: Task<SmartResponse, Never>? = nil

    @AtomicValue
    private var completionTask: Task<Void, Never>? = nil

    @AtomicValue
    private var isCancelled: Bool = false

    var cancelled: Bool {
        return $isCancelled.syncUnchecked { $0 }
    }

    func setNetworkTask(_ task: Task<SmartResponse, Never>) {
        $networkTask.syncUnchecked { $0 = task }
    }

    func setCompletionTask(_ task: Task<Void, Never>) {
        $completionTask.syncUnchecked { $0 = task }
    }

    func finishCompletion() {
        $completionTask.syncUnchecked { $0 = nil }
        $networkTask.syncUnchecked { $0 = nil }
    }

    func cancelAll() {
        $isCancelled.syncUnchecked { $0 = true }

        let network = $networkTask.syncUnchecked { stored in
            let current = stored
            stored = nil
            return current
        }
        let completion = $completionTask.syncUnchecked { stored in
            let current = stored
            stored = nil
            return current
        }

        network?.cancel()
        completion?.cancel()
    }
}

// MARK: - RequestManager

extension SmartRequestManager: RequestManager {
    /// Sends a request asynchronously.
    ///
    /// - Parameters:
    ///   - url: Target request URL.
    ///   - parameters: Request configuration.
    ///   - userInfo: Request metadata.
    /// - Returns: Raw network response.
    public func request(url: SmartURL, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse {
        return await startRequest(url: url, parameters: parameters, userInfo: userInfo)
    }

    /// Sends a request asynchronously using native ``URL`` value.
    ///
    /// - Parameters:
    ///   - url: Target request URL.
    ///   - parameters: Request configuration.
    ///   - userInfo: Request metadata.
    /// - Returns: Raw network response.
    public func request(url: URL, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse {
        return await request(url: .url(url), parameters: parameters, userInfo: userInfo)
    }

    /// Sends a request with callback-based completion handling.
    ///
    /// - Parameters:
    ///   - url: The target endpoint.
    ///   - parameters: Request configuration.
    ///   - userInfo: Contextual metadata for the request.
    ///   - completionQueue: Queue on which to deliver the final result.
    ///   - completion: A closure called with the `SmartResponse`.
    /// - Returns: A cancellable task handle.
    public func request(url: SmartURL,
                        parameters: Parameters = .init(),
                        userInfo: UserInfo = .init(),
                        completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                        completion: @escaping ResponseClosure) -> SmartTasking {
        let state = RequestCompletionState()
        return SmartTask {
            let unsendable = USendable(completion)
            let networkTask = Task.detached {
                return await self.request(url: url, parameters: parameters, userInfo: userInfo)
            }
            state.setNetworkTask(networkTask)

            let completionTask = Task.detached { [state, unsendable] in
                defer {
                    state.finishCompletion()
                }

                let data = await networkTask.value
                if state.cancelled {
                    return
                }

                do {
                    try data.checkCancellation()
                    if state.cancelled {
                        return
                    }

                    completionQueue.fire {
                        if state.cancelled {
                            return
                        }
                        unsendable.value(data)
                    }
                } catch {
                    // nothing to do. request was cancelled.
                }
            }
            state.setCompletionTask(completionTask)
        } cancelAction: {
            state.cancelAll()
        }
        .fillUserInfo(with: url)
    }

    /// Sends a request with callback-based completion handling using native ``URL``.
    ///
    /// - Parameters:
    ///   - url: The target endpoint.
    ///   - parameters: Request configuration.
    ///   - userInfo: Contextual metadata for the request.
    ///   - completionQueue: Queue on which to deliver the final result.
    ///   - completion: A closure called with the `SmartResponse`.
    /// - Returns: A cancellable task handle.
    public func request(url: URL,
                        parameters: Parameters = .init(),
                        userInfo: UserInfo = .init(),
                        completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                        completion: @escaping ResponseClosure) -> SmartTasking {
        return request(url: .url(url),
                       parameters: parameters,
                       userInfo: userInfo,
                       completionQueue: completionQueue,
                       completion: completion)
    }
}

private extension SmartRequestManager {
    /// Executes the request pipeline including plugins, retry logic, and `StopTheLine` handling.
    func startRequest(url: SmartURL, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse {
        func retryAction() async -> SmartResponse {
            return await startRequest(url: url, parameters: parameters, userInfo: userInfo)
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
            let request = try await createRequest(url: url, parameters: parameters, userInfo: userInfo)

            try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
            data = await request.start()
            try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
        } catch {
            data = .init(error: error, session: session)
        }

        do {
            for plugin in parameters.plugins {
                try await plugin.verify(parameters: parameters, userInfo: userInfo, response: data)
            }
        } catch {
            // In the event that the request already has an error, and the plugin throws a new one,
            // then we must reduce the existing one, because the error from the `Plugin` is more priority for the application
            data.set(error: error)
        }

        if await shouldRetry(data, url: url, parameters: parameters, userInfo: userInfo) {
            return await retryAction()
        }

        do {
            assert(!Thread.isMainThread)
            let waited = try await waitUntilRunning(parameters.shouldIgnoreStopTheLine)
            if waited {
                switch lastStopTheLineQueueAction {
                case .passOver:
                    break
                case .retry:
                    return await retryAction()
                case let .retryWithDelay(delay):
                    try await Task.sleep(seconds: delay)
                    return await retryAction()
                }
            } else {
                let action = try await checkStopTheLine(data, url: url, parameters: parameters, userInfo: userInfo)
                switch action {
                case .useOriginal:
                    break
                case let .passOver(newResponse):
                    data = newResponse
                case .retry:
                    return await retryAction()
                case let .retryWithDelay(delay):
                    try await Task.sleep(seconds: delay)
                    return await retryAction()
                }
            }
        } catch {
            // In the event that the request already has an error, and the plugin throws a new one,
            // then we must reduce the existing one, because the error from the `StopTheLine` is more priority for the application
            data.set(error: error)
        }

        for plugin in parameters.plugins {
            await plugin.didFinish(parameters: parameters, userInfo: userInfo, response: data)
        }

        return data
    }

    /// Suspends execution until the manager is running, unless bypass is specified.
    @discardableResult
    func waitUntilRunning(_ shouldIgnoreStopTheLine: Bool) async throws -> Bool {
        var waited = false

        if shouldIgnoreStopTheLine {
            return waited
        }

        while !isRunning {
            waited = true
            try await Task.sleep(seconds: 0.1)
        }
        return waited
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
    func createRequest(url: SmartURL, parameters: Parameters, userInfo: UserInfo) async throws -> SmartRequest {
        var urlRequest = try parameters.urlRequest(for: url)
        for plugin in parameters.plugins {
            try await plugin.prepare(parameters: parameters, userInfo: userInfo, request: &urlRequest, session: session)
        }

        let request = SmartRequest(url: url,
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
                          url: SmartURL,
                          parameters: Parameters,
                          userInfo: UserInfo) async throws -> StopTheLineResult {
        assert(Thread.isMainThread)

        guard let stopTheLine, !parameters.shouldIgnoreStopTheLine else {
            return .passOver(result)
        }

        let verificationResult = await stopTheLine.verify(response: result,
                                                          url: url,
                                                          parameters: parameters,
                                                          userInfo: userInfo)
        switch verificationResult {
        case .stopTheLine:
            isRunning = false
            let newFactory = Self(withPlugins: plugins, stopTheLine: nil, retrier: retrier, session: session)
            do {
                let action = try await stopTheLine.action(with: newFactory,
                                                          response: result,
                                                          url: url,
                                                          parameters: parameters,
                                                          userInfo: userInfo)
                switch action {
                case .retry:
                    lastStopTheLineQueueAction = .retry
                case .passOver,
                     .useOriginal:
                    lastStopTheLineQueueAction = .passOver
                case let .retryWithDelay(delay):
                    lastStopTheLineQueueAction = .retryWithDelay(delay)
                }

                isRunning = true
                return action
            } catch {
                lastStopTheLineQueueAction = .passOver
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
    func shouldRetry(_ data: SmartResponse, url: SmartURL, parameters: Parameters, userInfo: UserInfo) async -> Bool {
        let retryOrFinish = await retrier?.retryOrFinish(result: data, url: url, parameters: parameters, userInfo: userInfo)
        defer {
            userInfo.attemptsCount += 1
        }

        do {
            switch retryOrFinish ?? .doNotRetry {
            case .retry:
                return true

            case let .retryWithDelay(delay):
                try await Task.sleep(seconds: delay)
                return true

            case .doNotRetry:
                return false

            case let .doNotRetryWithError(error):
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
    /// Associates the request url with the userInfo metadata.
    func fillUserInfo(with url: SmartURL) -> Self {
        userInfo.smartRequestAddress = url
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
