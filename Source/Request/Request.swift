import Foundation
import Threading

#if swift(>=6.0)
public protocol Requestable: AnyObject, Sendable {
    typealias CompletionCallback = (RequestResult) -> Void

    var completion: CompletionCallback? { get set }
    var urlRequestable: URLRequestRepresentation { get }
    var parameters: Parameters { get }

    func start()
    func restart()
    func cancel()
}
#else
public protocol Requestable: AnyObject {
    typealias CompletionCallback = (RequestResult) -> Void

    var completion: CompletionCallback? { get set }
    var urlRequestable: URLRequestRepresentation { get }
    var parameters: Parameters { get }

    func start()
    func restart()
    func cancel()
}
#endif

public final class Request {
    private let sessionAdaptor: SessionAdaptor
    private let address: Address
    private var isCanceled: Bool = false

    public let parameters: Parameters
    public var userInfo: UserInfo {
        return parameters.userInfo
    }

    public let urlRequestable: URLRequestRepresentation

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    public var completion: CompletionCallback?

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    public var serviceCompletion: (() -> Void)?

    private var plugins: [Plugin] {
        return parameters.plugins
    }

    public init(address: Address,
                with parameters: Parameters,
                urlRequestable: URLRequestRepresentation) {
        self.address = address
        self.parameters = parameters
        self.urlRequestable = urlRequestable
        self.sessionAdaptor = .init(session: parameters.session,
                                    progressHandler: parameters.progressHandler)
    }

    deinit {
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
                            userInfo: userInfo)
        }

        let sdkRequest = urlRequestable.sdk
        if let stub = HTTPStubServer.shared.response(for: sdkRequest) {
            let response = sdkRequest.url.flatMap {
                return HTTPURLResponse(url: $0,
                                       statusCode: stub.statusCode.code,
                                       httpVersion: nil,
                                       headerFields: stub.header)
            }
            let responseData = RequestResult(request: urlRequestable,
                                             body: stub.body.data,
                                             response: response,
                                             error: stub.error)
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
                                                 error: nil)
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
                                             error: error)

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
        completion?(data)
    }

    private func tryFireCancellation() -> Bool {
        if isCanceled {
            serviceCompletion?()
            return false
        }
        return true
    }
}

// MARK: - Requestable

extension Request: Requestable {
    public func start() {
        startRealRequest()
    }

    public func restart() {
        isCanceled = false
        startRealRequest()
    }

    public func cancel() {
        isCanceled = true
        stopSessionRequest()

        for plugin in plugins {
            plugin.wasCancelled(parameters,
                                request: urlRequestable,
                                userInfo: userInfo)
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension Request: CustomDebugStringConvertible {
    public var debugDescription: String {
        return makeDescription()
    }
}

// MARK: - CustomStringConvertible

extension Request: CustomStringConvertible {
    public var description: String {
        return makeDescription()
    }
}

// MARK: - private

private final class SessionAdaptor {
    private let session: Session
    private let progressHandler: ProgressHandler?
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var task: SessionTask?
    private var observer: Any?

    required init(session: Session,
                  progressHandler: ProgressHandler?) {
        self.session = session
        self.progressHandler = progressHandler
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping CompletionHandler) {
        stop()

        let newTask = session.task(with: request) { [weak self] data, response, error in
            completionHandler(data, response, error)
            self?.stop()
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
        let method: String = (parameters.method?.toString()).map { $0 + " " } ?? ""
        return "<\(method)request: \(text)>"
    }
}

private extension [String: String]? {
    var postmanFormat: String {
        return (self ?? [:]).map {
            return [$0, $1].joined(separator: ":")
        }
        .joined(separator: "\n")
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
