import Foundation
import NQueue

public protocol Requestable: AnyObject {
    typealias CompletionCallback = (RequestResult) -> Void

    var userInfo: Parameters.UserInfo { get set }
    var completion: CompletionCallback? { get set }
    var urlRequestable: URLRequestRepresentation { get }
    var parameters: Parameters { get }

    func start()
    func cancel()
}

public final class Request {
    private let sessionAdaptor: SessionAdaptor
    private var isCanceled: Bool = false

    public private(set) var parameters: Parameters
    public var userInfo: Parameters.UserInfo
    public let urlRequestable: URLRequestRepresentation

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    public var completion: CompletionCallback?

    private var plugins: [RequestStatePlugin] {
        return parameters.plugins
    }

    private init(with parameters: Parameters,
                 userInfo: Parameters.UserInfo,
                 urlRequestable: URLRequestRepresentation) {
        self.parameters = parameters
        self.userInfo = userInfo
        self.urlRequestable = urlRequestable
        self.sessionAdaptor = .init(session: parameters.session,
                                    progressHandler: parameters.progressHandler)
    }

    public static func create(with parameters: Parameters,
                              urlRequestable: URLRequestRepresentation,
                              userInfo: Parameters.UserInfo = [:]) -> Requestable {
        return Self(with: parameters,
                    userInfo: userInfo,
                    urlRequestable: urlRequestable)
    }

    deinit {
        sessionAdaptor.stop()
    }

    private func startRealRequest() {
        cancel()
        isCanceled = false

        for plugin in plugins {
            plugin.willSend(parameters,
                            request: urlRequestable,
                            userInfo: &userInfo)
        }

        let sdkRequest = urlRequestable.sdk
        tologSelf(sdkRequest)

        if let stub = HTTPStubServer.shared.response(for: sdkRequest) {
            let response = HTTPURLResponse(url: sdkRequest.url.unsafelyUnwrapped,
                                           statusCode: stub.statusCode,
                                           httpVersion: nil,
                                           headerFields: stub.header)
            let responseData = RequestResult(request: urlRequestable,
                                             body: stub.body.data,
                                             response: response,
                                             error: stub.error)
            if let delay = stub.delayInSeconds {
                Queue.background.asyncAfter(deadline: .now() + delay) { [self] in
                    fire(data: responseData,
                         queue: parameters.queue)
                }
            } else {
                fire(data: responseData,
                     queue: parameters.queue)
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
                fire(data: responseData,
                     queue: cacheSettings.queue)
                return
            }
        }

        sessionAdaptor.dataTask(with: sdkRequest) { [weak self] data, response, error in
            guard let self, !self.isCanceled else {
                return
            }

            if let cacheSettings = self.parameters.cacheSettings, let response, let data, error == nil {
                let cached = CachedURLResponse(response: response,
                                               data: data,
                                               userInfo: nil,
                                               storagePolicy: cacheSettings.storagePolicy)
                cacheSettings.cache.storeCachedResponse(cached, for: sdkRequest)
            }

            self.tologSelf(sdkRequest)

            let responseData = RequestResult(request: self.urlRequestable,
                                             body: data,
                                             response: response,
                                             error: error)

            self.fire(data: responseData,
                      queue: self.parameters.queue)
        }
    }

    private func stopSessionRequest() {
        sessionAdaptor.stop()
    }

    private func fire(data: RequestResult,
                      queue: DelayedQueue) {
        tolog(data.body, allHTTPHeaderFields: urlRequestable.allHTTPHeaderFields)

        for plugin in plugins {
            plugin.didReceive(parameters,
                              request: urlRequestable,
                              data: data,
                              userInfo: &userInfo)
        }

        complete(in: queue,
                 with: data)

        stopSessionRequest()
    }

    private func complete(in queue: DelayedQueue,
                          with data: RequestResult) {
        queue.fire {
            self.completion?(data)
        }
    }
}

// MARK: - Requestable

extension Request: Requestable {
    public func start() {
        startRealRequest()
    }

    public func cancel() {
        isCanceled = true
        stopSessionRequest()
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

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
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
    func tolog(file: String = #file,
               method: String = #function,
               line: Int = #line,
               text: () -> String) {
        guard parameters.isLoggingEnabled else {
            return
        }

        Logger.log([
            "\(self)",
            text()
        ].joined(separator: "\n"),
        file: file,
        method: method,
        line: line)
    }

    func tologSelf(_ modifiedRequest: @autoclosure () -> URLRequest,
                   file: String = #file,
                   method: String = #function,
                   line: Int = #line) {
        guard parameters.isLoggingEnabled else {
            return
        }

        tolog(file: file,
              method: method,
              line: line) {
            return [
                "<with headers:",
                modifiedRequest().allHTTPHeaderFields.postmanFormat,
                ">"
            ].joined(separator: "\n")
        }
    }

    func tolog(_ data: @autoclosure () -> Data?,
               allHTTPHeaderFields: @autoclosure () -> [String: String]?,
               file: String = #file,
               method: String = #function,
               line: Int = #line) {
        guard parameters.isLoggingEnabled else {
            return
        }

        let text: String
        if let body = data(), !body.isEmpty {
            do {
                let json = try JSONSerialization.jsonObject(with: body, options: [.allowFragments])
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
                if let prettyStr = String(data: prettyData, encoding: .utf8) {
                    text = prettyStr
                } else {
                    text = String(data: body, encoding: .utf8) ?? "unexpected body"
                }
            } catch {
                text = "serialization error: " + error.localizedDescription
            }
        } else {
            text = "response: empty body"
        }

        Logger.log([
            "\(self)",
            "<with headers:",
            allHTTPHeaderFields().postmanFormat,
            ">",
            text
        ].joined(separator: "\n"),
        file: file,
        method: method,
        line: line)
    }

    func makeDescription() -> String {
        let url = try? parameters.address.url(shouldAddSlashAfterEndpoint: parameters.shouldAddSlashAfterEndpoint)
        let text = url?.absoluteString ?? "broken url"
        return "<\(parameters.method.toString()) request: \(text)>"
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
