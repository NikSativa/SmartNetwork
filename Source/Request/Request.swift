import Foundation
import Threading

internal final class Request {
    typealias CompletionCallback = (RequestResult) -> Void

    private lazy var sessionAdaptor: SessionAdaptor = {
        return .init(session: session, progressHandler: parameters.progressHandler)
    }()

    private let address: Address
    private var isCanceled: Bool = false

    let session: SmartURLSession
    let parameters: Parameters
    var userInfo: UserInfo {
        return parameters.userInfo
    }

    let urlRequestable: URLRequestRepresentation

    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    var completion: CompletionCallback?

    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    var serviceClosure: (() -> Void)?

    private var plugins: [Plugin] {
        return parameters.plugins
    }

    init(address: Address,
         parameters: Parameters,
         urlRequestable: URLRequestRepresentation,
         session: SmartURLSession) {
        self.address = address
        self.parameters = parameters
        self.urlRequestable = urlRequestable
        self.session = session
    }

    deinit {
        fireServiceClosure()
        sessionAdaptor.stop()
    }

    private func startRealRequest() {
        stopSessionRequest()

        guard tryFireCancellation() else {
            return
        }

        for plugin in plugins {
            plugin.willSend(parameters,
                            request: urlRequestable,
                            userInfo: userInfo,
                            session: session)
        }

        let sdkRequest = urlRequestable.sdk
        if let stub = HTTPStubServer.shared.response(for: sdkRequest) {
            let response: HTTPURLResponse? = sdkRequest.url.flatMap {
                return HTTPURLResponse(url: $0,
                                       statusCode: stub.statusCode.code,
                                       httpVersion: nil,
                                       headerFields: stub.header.mapToResponse())
            }
            let responseData = RequestResult(request: urlRequestable,
                                             body: stub.body?.data,
                                             response: response,
                                             error: stub.error,
                                             session: session)
            if let delay = stub.delayInSeconds, delay > 0 {
                HTTPStubServer.defaultResponseQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self, tryFireCancellation() else {
                        return
                    }

                    fireCompletionAndNotifyPlugins(data: responseData)
                }
            } else {
                HTTPStubServer.defaultResponseQueue.sync { [weak self] in
                    guard let self, tryFireCancellation() else {
                        return
                    }

                    fireCompletionAndNotifyPlugins(data: responseData)
                }
            }
            return
        }

        if let cacheSettings = parameters.cacheSettings {
            let shouldUseCache: Bool
            switch parameters.requestPolicy {
            case .reloadIgnoringLocalAndRemoteCacheData,
                 .reloadIgnoringLocalCacheData,
                 .reloadRevalidatingCacheData:
                parameters.cacheSettings?.cache.removeCachedResponse(for: sdkRequest)
                shouldUseCache = false
            case .returnCacheDataDontLoad,
                 .returnCacheDataElseLoad,
                 .useProtocolCachePolicy:
                shouldUseCache = true
            @unknown default:
                shouldUseCache = true
            }

            if shouldUseCache, let cached = cacheSettings.cache.cachedResponse(for: sdkRequest) {
                let responseData = RequestResult(request: urlRequestable,
                                                 body: cached.data,
                                                 response: cached.response,
                                                 error: nil,
                                                 session: session)
                cacheSettings.responseQueue.fire { [self] in
                    fireCompletionAndNotifyPlugins(data: responseData)
                }
                return
            }
        }

        sessionAdaptor.dataTask(with: sdkRequest) { [weak self] data, response, error in
            guard let self, tryFireCancellation() else {
                return
            }

            if let cacheSettings = parameters.cacheSettings, let response, let data, error == nil {
                let cached = CachedURLResponse(response: response,
                                               data: data,
                                               userInfo: nil,
                                               storagePolicy: cacheSettings.storagePolicy)
                cacheSettings.cache.storeCachedResponse(cached, for: sdkRequest)
            }

            let responseData = RequestResult(request: urlRequestable,
                                             body: data,
                                             response: response,
                                             error: error,
                                             session: session)

            fireCompletionAndNotifyPlugins(data: responseData)
        }
    }

    private func stopSessionRequest() {
        sessionAdaptor.stop()
    }

    private func fireCompletionAndNotifyPlugins(data: RequestResult) {
        for plugin in plugins {
            plugin.didReceive(parameters,
                              request: urlRequestable,
                              data: data,
                              userInfo: userInfo)
        }

        fireCompletion(data: data)
    }

    private func fireCompletion(data: RequestResult) {
        stopSessionRequest()

        let completion = completion
        self.completion = nil
        completion?(data)
    }

    private func tryFireCancellation() -> Bool {
        if isCanceled {
            fireServiceClosure()
            return false
        }
        return true
    }

    private func fireServiceClosure() {
        let serviceCompletion = serviceClosure
        serviceClosure = nil
        serviceCompletion?()
    }
}

extension Request {
    /// Starts the request.
    /// - Returns: `true` if the request was started, `false` if the request was canceled.
    func tryStart() -> Bool {
        if isCanceled {
            fireServiceClosure()
            return false
        }

        startRealRequest()
        return true
    }

    func cancel() {
        isCanceled = true
        stopSessionRequest()

        for plugin in plugins {
            plugin.wasCancelled(parameters,
                                request: urlRequestable,
                                userInfo: userInfo,
                                session: session)
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Request: CustomDebugStringConvertible {
    var debugDescription: String {
        return makeDescription()
    }
}

// MARK: - CustomStringConvertible

extension Request: CustomStringConvertible {
    var description: String {
        return makeDescription()
    }
}

// MARK: - private

private final class SessionAdaptor {
    private let session: SmartURLSession
    private let progressHandler: ProgressHandler?
    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var task: SessionTask?
    private var observer: Any?

    required init(session: SmartURLSession,
                  progressHandler: ProgressHandler?) {
        self.session = session
        self.progressHandler = progressHandler
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping CompletionHandler) {
        stop()

        let newTask = session.task(with: request) { [weak self] data, response, error in
            self?.stop()
            completionHandler(data, response, error)
        }

        if let progressHandler {
            observer = newTask.progress.observe(progressHandler)
        }
        task = newTask
        newTask.resume()
    }

    func stop() {
        $task.mutate { task in
            if task?.isRunning == true {
                task?.cancel()
            }
            task = nil
        }
        observer = nil
    }

    deinit {
        stop()
    }
}

private extension Request {
    func makeDescription() -> String {
        let url = try? address.url()
        let text = url?.absoluteString ?? "broken url"
        let method: String = (parameters.method ?? .other("`No method`")).toString()
        return "<\(method) request: \(text)" + (parameters.header.isEmpty ? "" : " headers: \(parameters.header)") + ">"
    }
}

#if swift(>=6.0)
extension Request: @unchecked Sendable {}
extension SessionAdaptor: @unchecked Sendable {
    typealias CompletionHandler = @Sendable (Data?, URLResponse?, Error?) -> Void
}
#else
extension SessionAdaptor {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
}
#endif
