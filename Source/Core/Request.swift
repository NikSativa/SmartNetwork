import Foundation

class Request<Response: InternalDecodable, Error: AnyError> {
    typealias CompleteCallback = (Result<Response.Object, Error>) -> Void

    private var completeCallback: CompleteCallback?
    func onComplete(_ callback: @escaping CompleteCallback) {
        completeCallback = callback
    }

    // MARK: -
    private var sdkRequest: URLRequest
    private var isStopped: Bool = false
    private var sessionAdaptor: SessionAdaptor?

    func start() {
        stop()
        isStopped = false

        plugins.forEach {
            sdkRequest = $0.prepare(info)
        }

        plugins.forEach {
            $0.willSend(info)
        }

        if let cached = parameters.cacheSettings?.cache.cachedResponse(for: sdkRequest) {
            fire(data: cached.data, response: cached.response, error: nil)
            return
        }

        tolog("sending \(parameters.method.toString()) request: " +
                "\n" +
                "\(sdkRequest.url?.absoluteString ?? "<url is nil>")" +
                "\n" +
                "with headers: " +
                "\n" +
                "\(String(describing: sdkRequest.allHTTPHeaderFields ?? [:]))")

        let sessionAdaptor = SessionAdaptor(taskKind: parameters.taskKind)
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
            self.fire(data: data, response: response, error: error)
        }
    }

    func stop() {
        isStopped = true
        sessionAdaptor?.stop()
        sessionAdaptor = nil
    }

    deinit {
        sessionAdaptor?.stop()
    }

    private var info: PluginInfo {
        return .init(request: sdkRequest, parameters: parameters)
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

    private func fire(data: Data?, response: URLResponse?, error: Swift.Error?) {
        var httpStatusCode: Int?
        var header: [AnyHashable: Any] = [:]
        if let response = response as? HTTPURLResponse {
            httpStatusCode = response.statusCode
            header = response.allHeaderFields
        }

        let didfinish = {
            self.plugins.forEach {
                $0.didFinish(self.info, response: response, with: error, statusCode: httpStatusCode)
            }
        }

        do {
            tolog({
                let obj = { try? JSONSerialization.jsonObject(with: data ?? Data(), options: JSONSerialization.ReadingOptions())}
                return "response: " + (String(data: data ?? Data(), encoding: .utf8) ?? obj().map({ String(describing: $0) }) ?? "nil")
            }())

            try plugins.forEach {
                try $0.verify(httpStatusCode: httpStatusCode, header: header, data: data, error: error)
            }

            let resultResponse = try Response(with: data)
            parameters.queue.async {
                self.completeCallback?(.success(resultResponse.content))
                didfinish()
            }
        } catch let resultError {
            let completionHandler = { [weak self] in
                guard let self = self else {
                    return
                }

                self.parameters.queue.async {
                    self.tolog("failed request: \(resultError)")
                    self.completeCallback?(.failure(Error.wrap(resultError)))
                    didfinish()
                }
            }

            let retryCompletion: (Bool) -> Void = { [weak self] shouldRetry in
                if shouldRetry {
                    self?.start()
                } else {
                    completionHandler()
                }
            }

            if plugins.first(where: { $0.should(wait: info, response: response, with: resultError, forRetryCompletion: retryCompletion) }) == nil {
                completionHandler()
            }
        }
    }

    private let parameters: Parameters
    required init(_ parameters: Parameters) throws {
        self.parameters = parameters

        var request = URLRequest(url: try parameters.address.url(),
                                 cachePolicy: parameters.requestPolicy,
                                 timeoutInterval: parameters.timeoutInterval)
        request.httpMethod = parameters.method.toString()

        for (key, value) in parameters.header {
            request.addValue(value, forHTTPHeaderField: key)
        }

        try parameters.body.fill(&request, isLoggingEnabled: parameters.isLoggingEnabled)

        sdkRequest = request
    }
}

extension Request: CustomDebugStringConvertible {
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
