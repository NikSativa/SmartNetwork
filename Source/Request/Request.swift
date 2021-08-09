import Foundation
import NQueue

public enum SpecialCompletionAction: Equatable {
    /// response will be delivered to the real request
    case passOver

    /// response will be ignored
    case ignore
}

public protocol MutableRequest: AnyObject {
    var info: RequestInfo { get }
    func set(_ parameters: Parameters) throws

    typealias SpecialCompletionCallback = (_ httpStatusCode: Int?, _ header: [AnyHashable: Any], _ data: Data?, _ error: Error?) -> SpecialCompletionAction
    func onSpecialComplete(_ callback: @escaping SpecialCompletionCallback)
    func cancelSpecialCompletion()
}

protocol ScheduledRequest: MutableRequest {
    var isSpecial: Bool { get }
    func start()
}

protocol Request: ScheduledRequest {
    associatedtype Response: CustomDecodable
    associatedtype Error: AnyError

    func stop()

    typealias CompletionCallback = (Result<Response.Object, Error>) -> Void
    func onComplete(_ callback: @escaping CompletionCallback)
}

extension Impl {
    final class Request<Response: CustomDecodable, Error: AnyError>: NRequest.Request {
        typealias CompletionCallback = (Result<Response.Object, Error>) -> Void
        private var completeCallback: CompletionCallback?
        private var specialCompleteCallback: SpecialCompletionCallback?

        // MARK: -
        private var isStopped: Bool = false
        private var sessionAdaptor: SessionAdaptor?

        @Atomic
        private var parameters: Parameters

        @Atomic
        private var sdkRequest: URLRequest

        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var cachedRequestInfo: RequestInfo?

        var info: RequestInfo {
            if let requestInfo = cachedRequestInfo {
                return requestInfo
            }
            
            let info = prepare()
            cachedRequestInfo = info
            return info
        }

        var isSpecial: Bool {
            return specialCompleteCallback != nil
        }

        required init(parameters: Parameters) throws {
            self._parameters = Atomic(wrappedValue: parameters,
                                      mutex: Mutex.pthread(.recursive),
                                      read: .sync,
                                      write: .sync)
            _sdkRequest = Atomic(wrappedValue: try parameters.sdkRequest(),
                                 mutex: Mutex.pthread(.recursive),
                                 read: .sync,
                                 write: .sync)
        }

        deinit {
            sessionAdaptor?.stop()
        }

        private func prepare() -> RequestInfo {
            var info = RequestInfo(request: sdkRequest,
                                   parameters: parameters)
            plugins.forEach {
                $0.prepare(&info)
            }

            cachedRequestInfo = info
            return info
        }

        func set(_ parameters: Parameters) throws {
            stop()

            self.parameters = parameters
            sdkRequest = try parameters.sdkRequest()
            cachedRequestInfo = prepare()
        }

        func start() {
            let info = info
            cachedRequestInfo = nil

            stop()
            isStopped = false

            plugins.forEach {
                $0.willSend(info)
            }

            if let cacheSettings = parameters.cacheSettings,
               !isSpecial {
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
                    fire(data: cached.data,
                         response: cached.response as? HTTPURLResponse,
                         error: nil,
                         queue: cacheSettings.queue,
                         info: info)
                    return
                }
            }

            let sessionAdaptor = SessionAdaptor(parameters: parameters)
            self.sessionAdaptor = sessionAdaptor

            sessionAdaptor.dataTask(with: sdkRequest) { [weak self] data, response, error in
                guard let self = self, !self.isStopped else {
                    return
                }

                if let cacheSettings = self.parameters.cacheSettings, let response = response, let data = data, error == nil {
                    let cached = CachedURLResponse(response: response,
                                                   data: data,
                                                   userInfo: nil,
                                                   storagePolicy: cacheSettings.storagePolicy)
                    cacheSettings.cache.storeCachedResponse(cached, for: self.sdkRequest)
                }

                self.sessionAdaptor = nil
                self.tologSelf(self.sdkRequest)

                let httpResponse = response as? HTTPURLResponse
                let action: SpecialCompletionAction
                if let specialCompleteCallback = self.specialCompleteCallback {
                    action = specialCompleteCallback(httpResponse?.statusCode,
                                                                 httpResponse?.allHeaderFields ?? [:],
                                                                 data,
                                                                 error)
                } else {
                    action = .passOver
                }

                switch action {
                case .passOver:
                    self.fire(data: data,
                              response: httpResponse,
                              error: error.map { .wrap($0) },
                              queue: self.parameters.queue,
                              info: info)
                case .ignore:
                    self.cancelSpecialCompletion()
                }
            }
        }

        func onComplete(_ callback: @escaping CompletionCallback) {
            completeCallback = callback
        }

        func onSpecialComplete(_ callback: @escaping SpecialCompletionCallback) {
            specialCompleteCallback = callback
            start()
        }

        func cancelSpecialCompletion() {
            specialCompleteCallback = nil
            stopSessionRequest()
        }

        func stop() {
            isStopped = true
            stopSessionRequest()
        }

        private func stopSessionRequest() {
            sessionAdaptor?.stop()
            sessionAdaptor = nil
        }

        private var plugins: [Plugin] {
            return parameters.plugins
        }

        private func tolog(_ text: @autoclosure () -> String, file: String = #file, method: String = #function) {
            guard parameters.isLoggingEnabled else {
                return
            }

            Configuration.log("\(self)", file: file, method: method)
            Configuration.log(text(), file: file, method: method)
        }

        private func tologSelf(_ modifiedRequest: URLRequest, file: String = #file, method: String = #function) {
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
                  method: method)
        }

        private func tolog(_ data: Data?, file: String = #file, method: String = #function) {
            guard parameters.isLoggingEnabled else {
                return
            }

            let text: String
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    let str = String(describing: json)
                    text = "response: \n" + str
                } else if let strFromData = String(data: data, encoding: .utf8) {
                    text = strFromData
                } else {
                    text = "response: not empty body (can't decode for logging)"
                }
            } else {
                text = "response: empty body"
            }

            Configuration.log("\(self)", file: file, method: method)
            Configuration.log(text, file: file, method: method)
        }

        private func fire(data: Data?,
                          response: HTTPURLResponse?,
                          error: Error?,
                          queue: DelayedQueue,
                          info: RequestInfo) {
            var resultError = error
            let httpStatusCode: Int? = response?.statusCode
            let allHeaderFields: [AnyHashable: Any] = response?.allHeaderFields ?? [:]

            if let error = error {
                queue.fire {
                    self.complete(.failure(error), in: queue)
                }
            } else {
                do {
                    tolog(data)

                    try plugins.forEach {
                        try $0.verify(httpStatusCode: httpStatusCode,
                                      header: allHeaderFields,
                                      data: data,
                                      error: nil)
                    }

                    let resultResponse = try Response(with: data, statusCode: httpStatusCode, headers: allHeaderFields)
                    queue.fire {
                        self.complete(.success(resultResponse.content), in: queue)
                    }
                } catch let catchedError {
                    self.tolog("failed request: \(catchedError)")
                    let wrappedError: Error = .wrap(catchedError)
                    resultError = wrappedError

                    queue.fire {
                        self.complete(.failure(wrappedError), in: queue)
                    }
                }
            }

            plugins.forEach {
                $0.didFinish(info,
                             response: response,
                             with: resultError.map { Error.wrap($0) },
                             responseBody: data,
                             statusCode: httpStatusCode)
            }

            stopSessionRequest()
        }

        private func complete(_ result: Result<Response.Object, Error>,
                              in queue: DelayedQueue) {
            queue.fire {
                self.completeCallback?(result)
            }
        }
    }
}

extension Impl.Request: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<Request: \(sdkRequest)>"
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

    private var task: SessionTask?
    private var buffer: NSMutableData = NSMutableData()
    private var dataTask: SessionTask?
    private var expectedContentLength: Int64 = 0
    private var observer: AnyObject?

    required init(parameters: Parameters) {
        self.parameters = parameters
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = session.task(with: request) { [weak self] data, response, error in
            completionHandler(data, response, error)
            self?.stop()
        }

        if let progressHandler = parameters.taskKind?.progressHandler {
            if #available(iOS 11, *) {
                observer = task.observe(progressHandler)
            } else {
                progressHandler(.init(fractionCompleted: 0))
            }
        }

        self.task = task
        task.resume()
    }

    func stop() {
        if task?.isRunning == true {
            task?.cancel()
        }
        task = nil
    }

    deinit {
        invalidator?()
        stop()
    }
}

extension SessionAdaptor: SessionDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int64(response.expectedContentLength)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        parameters.taskKind?.downloadProgressHandler?(progress(totalBytesSent: Int64(buffer.length), totalBytesExpectedToSend: expectedContentLength))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        parameters.taskKind?.downloadProgressHandler?(.init(fractionCompleted: 1))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
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
