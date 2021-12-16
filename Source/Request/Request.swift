import Foundation
import NQueue

// sourcery: fakable
public protocol Request: AnyObject {
    typealias CompletionCallback = (ResponseData) -> Void
    var completion: CompletionCallback? { get set }

    var parameters: Parameters { get }

    func cancel()
    func start()
}

extension Impl {
    final class Request {
        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var sessionAdaptor: SessionAdaptor?
        private var isCanceled: Bool = false
        private let pluginContext: PluginProvider
        private(set) var parameters: Parameters

        var completion: CompletionCallback?

        required init(parameters: Parameters,
                      pluginContext: PluginProvider?) {
            self.parameters = parameters
            self.pluginContext = pluginContext ?? PluginProviderContext()
        }

        deinit {
            sessionAdaptor?.stop()
        }

        private func startRealRequest() {
            cancel()
            isCanceled = false

            do {
                let request = try parameters.sdkRequest()
                var requestable: NRequest.URLRequestable = Impl.URLRequestable(request)
                for plugin in plugins {
                    plugin.prepare(parameters,
                                   request: &requestable,
                                   userInfo: &parameters.userInfo)
                }

                start(with: requestable)
            } catch {
                let data = ResponseData(request: nil,
                                        body: nil,
                                        response: nil,
                                        error: error,
                                        userInfo: parameters.userInfo)
                complete(in: parameters.queue,
                         with: data)
            }
        }

        private func start(with requestable: NRequest.URLRequestable) {
            plugins.forEach {
                $0.willSend(parameters, request: requestable)
            }

            let sdkRequest = requestable.original
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
                    tologSelf(sdkRequest)
                    let responseData = ResponseData(request: requestable,
                                                    body: cached.data,
                                                    response: cached.response,
                                                    error: nil,
                                                    userInfo: self.parameters.userInfo)
                    fire(data: responseData,
                         queue: cacheSettings.queue,
                         sdkRequest: requestable)
                    return
                }
            }

            let sessionAdaptor: SessionAdaptor = $sessionAdaptor.mutate { sessionAdaptor in
                let new = SessionAdaptor(parameters: parameters)
                sessionAdaptor = new
                return new
            }

            sessionAdaptor.dataTask(with: sdkRequest) { [weak self] data, response, error in
                guard let self = self, !self.isCanceled else {
                    return
                }

                if let cacheSettings = self.parameters.cacheSettings, let response = response, let data = data, error == nil {
                    let cached = CachedURLResponse(response: response,
                                                   data: data,
                                                   userInfo: nil,
                                                   storagePolicy: cacheSettings.storagePolicy)
                    cacheSettings.cache.storeCachedResponse(cached, for: sdkRequest)
                }

                self.sessionAdaptor?.clear()
                self.sessionAdaptor = nil

                self.tologSelf(sdkRequest)

                let responseData = ResponseData(request: requestable,
                                                body: data,
                                                response: response,
                                                error: error,
                                                userInfo: self.parameters.userInfo)

                self.fire(data: responseData,
                          queue: self.parameters.queue,
                          sdkRequest: requestable)
            }
        }

        private func stopSessionRequest() {
            sessionAdaptor?.stop()
            sessionAdaptor = nil
        }

        private var plugins: [Plugin] {
            return parameters.plugins + pluginContext.plugins()
        }

        private func fire(data: ResponseData,
                          queue: DelayedQueue,
                          sdkRequest: NRequest.URLRequestable) {
            do {
                tolog(data.body)
                try plugins.forEach {
                    try $0.verify(data: data)
                }
            } catch let catchedError {
                self.tolog("failed request: \(catchedError)")
                data.error = catchedError
            }

            plugins.forEach {
                $0.didReceive(parameters,
                              data: data)
            }

            complete(in: queue,
                     with: data)

            stopSessionRequest()
        }

        private func complete(in queue: DelayedQueue,
                              with data: ResponseData) {
            queue.fire {
                self.completion?(data)
            }
        }
    }
}

extension Impl.Request: Request {
    func start() {
        startRealRequest()
    }

    func cancel() {
        isCanceled = true
        stopSessionRequest()
    }
}

extension Impl.Request {
    private func tolog(_ text: @autoclosure () -> String,
                       file: String = #file,
                       method: String = #function,
                       line: Int = #line) {
        guard parameters.isLoggingEnabled else {
            return
        }

        Logger.log("\(self)", file: file, method: method, line: line)
        Logger.log(text(), file: file, method: method, line: line)
    }

    private func tologSelf(_ modifiedRequest: URLRequest,
                           file: String = #file,
                           method: String = #function,
                           line: Int = #line) {
        tolog("request: " +
            "\n" +
            "method:" + parameters.method.toString() +
            "\n" +
            "\(modifiedRequest.url?.absoluteString ?? "<url is nil>")" +
            "\n" +
            "with headers: " +
            "\n" +
            "\(String(describing: modifiedRequest.allHTTPHeaderFields ?? [:]))",
            file: file,
            method: method,
            line: line)
    }

    private func tolog(_ data: Data?,
                       file: String = #file,
                       method: String = #function,
                       line: Int = #line) {
        guard parameters.isLoggingEnabled else {
            return
        }

        let text: String
        if let body = data, !body.isEmpty {
            do {
                let json = try JSONSerialization.jsonObject(with: body, options: [.allowFragments])
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
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

        Logger.log("\(self)", file: file, method: method, line: line)
        Logger.log(text, file: file, method: method, line: line)
    }
}

extension Impl.Request: CustomDebugStringConvertible {
    var debugDescription: String {
        let url = try? parameters.address.url()
        let text = url?.absoluteString ?? "broken url"
        return "<Request: \(text)>"
    }
}

private final class SessionAdaptor: NSObject {
    private let parameters: Parameters
    private var invalidator: (() -> Void)?

    private lazy var session: Session = {
        if let _ = parameters.taskKind {
            if #available(iOS 11, *) {
                return parameters.session
            } else {
                let session = parameters.session.copy(with: self)
                invalidator = { [weak session] in
                    session?.finishTasksAndInvalidate()
                }
                return session
            }
        } else {
            return parameters.session
        }
    }()

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var task: SessionTask?
    private var buffer = NSMutableData()
    private var dataTask: SessionTask?
    private var expectedContentLength: Int64 = 0
    private var observer: AnyObject?

    required init(parameters: Parameters) {
        self.parameters = parameters
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        stop()

        let newTask = session.task(with: request) { [weak self] data, response, error in
            completionHandler(data, response, error)
            self?.stop()
        }

        if let progressHandler = parameters.taskKind?.progressHandler {
            if #available(iOS 11, *) {
                observer = newTask.observe(progressHandler)
            } else {
                progressHandler(.init(fractionCompleted: 0))
            }
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
    }

    func clear() {
        task = nil
    }

    deinit {
        invalidator?()
        stop()
    }
}

extension SessionAdaptor: SessionDelegate {
    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int64(response.expectedContentLength)
        completionHandler(.allow)
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        parameters.taskKind?.downloadProgressHandler?(progress(totalBytesSent: Int64(buffer.length), totalBytesExpectedToSend: expectedContentLength))
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError _: Error?) {
        parameters.taskKind?.downloadProgressHandler?(.init(fractionCompleted: 1))
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didSendBodyData _: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        parameters.taskKind?.uploadProgressHandler?(progress(totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend))
    }

    private func progress(totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Progress {
        let percentageDownloaded: Double
        if totalBytesExpectedToSend > 0 {
            percentageDownloaded = min(1, max(0, Double(totalBytesSent) / Double(totalBytesExpectedToSend)))
        } else {
            percentageDownloaded = 0
        }
        return .init(fractionCompleted: percentageDownloaded)
    }
}

private extension Parameters.TaskKind {
    var progressHandler: ProgressHandler {
        switch self {
        case .download(let progressHandler),
             .upload(let progressHandler):
            return progressHandler
        }
    }

    var downloadProgressHandler: ProgressHandler? {
        switch self {
        case .download(let progressHandler):
            return progressHandler
        case .upload:
            return nil
        }
    }

    var uploadProgressHandler: ProgressHandler? {
        switch self {
        case .download:
            return nil
        case .upload(let progressHandler):
            return progressHandler
        }
    }
}

private extension Parameters {
    func sdkRequest() throws -> URLRequest {
        var request = URLRequest(url: try address.url(),
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method.toString()

        for (key, value) in header {
            request.addValue(value, forHTTPHeaderField: key)
        }

        try body.fill(&request, isLoggingEnabled: isLoggingEnabled)
        return request
    }
}
