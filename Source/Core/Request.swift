import Foundation

protocol Request {
    associatedtype Response: CustomDecodable
    associatedtype Error: AnyError

    func start()
    func stop()

    typealias CompletionCallback = (Result<Response.Object, Error>) -> Void
    func onComplete(_ callback: @escaping CompletionCallback)
}

extension Impl {
    final
    class Request<Response: CustomDecodable, Error: AnyError>: NRequest.Request {
        private var completeCallback: CompletionCallback?
        func onComplete(_ callback: @escaping CompletionCallback) {
            completeCallback = callback
        }

        // MARK: -
        private var sdkRequest: URLRequest
        private var isStopped: Bool = false
        private var sessionAdaptor: SessionAdaptor?
        private let parameters: Parameters

        required init(_ parameters: Parameters) throws {
            self.parameters = parameters
            sdkRequest = try parameters.sdkRequest()
        }

        deinit {
            sessionAdaptor?.stop()
        }

        func start() {
            stop()
            isStopped = false

            var info = RequestInfo(request: sdkRequest,
                                   parameters: parameters)
            plugins.forEach {
                $0.prepare(&info)
            }
            let modifiedRequest = info.request.original

            plugins.forEach {
                $0.willSend(info)
            }

            if let cacheSettings = parameters.cacheSettings, let cached = cacheSettings.cache.cachedResponse(for: modifiedRequest) {
                fire(data: cached.data,
                     response: cached.response,
                     error: nil,
                     queue: cacheSettings.queue,
                     info: info)
                return
            }

            tolog("sending \(parameters.method.toString()) request: " +
                    "\n" +
                    "\(modifiedRequest.url?.absoluteString ?? "<url is nil>")" +
                    "\n" +
                    "with headers: " +
                    "\n" +
                    "\(String(describing: modifiedRequest.allHTTPHeaderFields ?? [:]))")

            let sessionAdaptor = SessionAdaptor(taskKind: parameters.taskKind)
            self.sessionAdaptor = sessionAdaptor

            sessionAdaptor.dataTask(with: modifiedRequest) { [weak self] data, response, error in
                guard let self = self, !self.isStopped else {
                    return
                }

                if let cacheSettings = self.parameters.cacheSettings, let response = response, let data = data, error == nil {
                    let cached = CachedURLResponse(response: response,
                                                   data: data,
                                                   userInfo: nil,
                                                   storagePolicy: cacheSettings.storagePolicy)
                    cacheSettings.cache.storeCachedResponse(cached, for: modifiedRequest)
                }

                self.sessionAdaptor = nil
                self.fire(data: data,
                          response: response,
                          error: error,
                          queue: self.parameters.queue,
                          info: info)
            }
        }

        func stop() {
            isStopped = true
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

        private func fire(data: Data?,
                          response: URLResponse?,
                          error: Swift.Error?,
                          queue: ResponseQueue,
                          info: RequestInfo) {
            var httpStatusCode: Int?
            var allHeaderFields: [AnyHashable: Any] = [:]
            if let response = response as? HTTPURLResponse {
                httpStatusCode = response.statusCode
                allHeaderFields = response.allHeaderFields
            }

            if let error = error {
                queue.fire {
                    self.completeCallback?(.failure(.wrap(error)))
                }
            } else {
                do {
                    tolog({
                        let obj = { try? JSONSerialization.jsonObject(with: data ?? Data(), options: JSONSerialization.ReadingOptions())}
                        return "response: " + (String(data: data ?? Data(), encoding: .utf8) ?? obj().map({ String(describing: $0) }) ?? "nil")
                    }())

                    try plugins.forEach {
                        try $0.verify(httpStatusCode: httpStatusCode,
                                      header: allHeaderFields,
                                      data: data,
                                      error: error)
                    }

                    let resultResponse = try Response(with: data)
                    queue.fire {
                        self.completeCallback?(.success(resultResponse.content))
                    }
                } catch let resultError {
                    self.tolog("failed request: \(resultError)")

                    queue.fire {
                        self.completeCallback?(.failure(.wrap(resultError)))
                    }
                }
            }

            self.plugins.forEach {
                $0.didFinish(info,
                             response: response,
                             with: error,
                             statusCode: httpStatusCode)
            }

            self.stop()
        }
    }
}

extension Impl.Request: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<Request: \(sdkRequest)>"
    }
}

private class SessionAdaptor: NSObject {
    private let taskKind: Parameters.TaskKind
    private var invalidator: (() -> Void)?

    private lazy var session: URLSession = {
        if taskKind.hasHandler {
            if #available(iOS 11, *) {
                return Configuration.session
            } else {
                let session = URLSession(configuration: Configuration.session.configuration,
                                         delegate: self,
                                         delegateQueue: nil)
                invalidator = { [weak session] in
                    session?.finishTasksAndInvalidate()
                }
                return session
            }
        } else {
            return Configuration.session
        }
    }()

    private var task: URLSessionDataTask?
    private var buffer: NSMutableData = NSMutableData()
    private var dataTask: URLSessionDataTask?
    private var expectedContentLength: Int64 = 0
    private var progress: NSKeyValueObservation?

    required init(taskKind: Parameters.TaskKind) {
        self.taskKind = taskKind

        super.init()
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            completionHandler(data, response, error)
            self?.stop()
        }

        if let progressHandler = taskKind.progressHandler {
            if #available(iOS 11, *) {
                progress = task.progress.observe(\.fractionCompleted, changeHandler: { progress, _ in
                    progressHandler(.init(fractionCompleted: progress.fractionCompleted))
                })
            } else {
                progressHandler(.init(fractionCompleted: 0))
            }
        }

        self.task = task
        task.resume()
    }

    func stop() {
        if task?.state == .running {
            task?.cancel()
        }
        task = nil
    }

    deinit {
        invalidator?()
        stop()
    }
}

extension SessionAdaptor: URLSessionDelegate, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int64(response.expectedContentLength)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        taskKind.downloadProgressHandler?(progress(totalBytesSent: Int64(buffer.length), totalBytesExpectedToSend: expectedContentLength))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        taskKind.downloadProgressHandler?(.init(fractionCompleted: 1))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        taskKind.uploadProgressHandler?(progress(totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend))
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
    var hasHandler: Bool {
        return progressHandler != nil
    }

    var progressHandler: ProgressHandler? {
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

//extension Impl.Request {
//    func toAny() -> AnyRequest<Response.Object, Error> {
//        AnyRequest(self)
//    }
//}
//
//class AnyRequest<Response, Error: AnyError>: Requesting {
//    private let box: AbstractRequest<Response, Error>
//
//    init<Requestable: Request>(_ storage: Requestable) where Requestable.Response == Response, Requestable.Error == Error {
//        box = RequestBox(storage)
//    }
//
//    func start() {
//        box.start()
//    }
//
//    func stop() {
//        box.stop()
//    }
//
//    func onComplete(_ callback: @escaping (Result<Response, Error>) -> Void) {
//        box.onComplete(callback)
//    }
//}
//
//private class AbstractRequest<Response, Error: AnyError>: Request {
//    func start() {
//        fatalError("abstract needs override")
//    }
//
//    func stop() {
//        fatalError("abstract needs override")
//    }
//
//    func onComplete(_ callback: @escaping CompleteCallback) {
//        fatalError("abstract needs override")
//    }
//}
//
//final
//private class RequestBox<Requestable: Request>: AbstractRequest<Requestable.Response, Requestable.Error> {
//    private let concrete: Requestable
//
//    init(_ concrete: Requestable) {
//        self.concrete = concrete
//    }
//
//    override func start() {
//        concrete.start()
//    }
//
//    override func stop() {
//        concrete.stop()
//    }
//
//    override func onComplete(_ callback: @escaping CompleteCallback) {
//        concrete.onComplete(callback)
//    }
//}
