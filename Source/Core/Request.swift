import Foundation

private class SessionAdaptor: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    private let progressHandler: ProgressHandler?
    private var session: URLSession {
        if let _ = progressHandler {
            if #available(iOS 11, *) {
                return Configuration.session
            } else {
                return URLSession(configuration: Configuration.session.configuration,
                                  delegate: self,
                                  delegateQueue: nil)
            }
        } else {
            return Configuration.session
        }
    }

    private var buffer: NSMutableData = NSMutableData()
    private var dataTask: URLSessionDataTask?
    private var expectedContentLength = 0
    private var progress: NSKeyValueObservation?

    required init(progressHandler: ProgressHandler?) {
        self.progressHandler = progressHandler

        super.init()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        expectedContentLength = Int(response.expectedContentLength)
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)

        let percentageDownloaded = Double(buffer.length) / Double(expectedContentLength)
        progressHandler?(.init(fractionCompleted: percentageDownloaded))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        progressHandler?(.init(fractionCompleted: 1))
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: request, completionHandler: completionHandler)

        if let progressHandler = progressHandler {
            if #available(iOS 11, *) {
                progress = task.progress.observe(\.fractionCompleted, changeHandler: { progress, _ in
                    progressHandler(.init(fractionCompleted: progress.fractionCompleted))
                })
            } else {
                progressHandler(.init(fractionCompleted: 0))
            }
        }

        return task
    }
}

class Request<Response: InternalDecodable, Error: AnyError> {
    typealias CompleteCallback = (Result<Response.Object, Error>) -> Void

    private var completeCallback: CompleteCallback?
    func onComplete(_ callback: @escaping CompleteCallback) {
        completeCallback = callback
    }

    // MARK: -
    private var task: URLSessionDataTask?
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

        if let cached = parameters.cacheSettings.cache?.cachedResponse(for: sdkRequest) {
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

        let sessionAdaptor = SessionAdaptor(progressHandler: parameters.progressHandler)
        self.sessionAdaptor = sessionAdaptor

        task = sessionAdaptor.dataTask(with: sdkRequest) { [weak self] data, response, error in
            guard let self = self else {
                return
            }

            if !self.isStopped, let cache = self.parameters.cacheSettings.cache, let response = response, let data = data, error == nil {
                let cached = CachedURLResponse(response: response,
                                               data: data,
                                               userInfo: nil,
                                               storagePolicy: self.parameters.cacheSettings.storagePolicy)
                cache.storeCachedResponse(cached, for: self.sdkRequest)
            }

            self.task = nil
            self.sessionAdaptor = nil
            self.fire(data: data, response: response, error: error)
        }

        task?.resume()
    }

    func stop() {
        isStopped = true

        if task?.state == .running {
            task?.cancel()
        }

        task = nil
        sessionAdaptor = nil
    }

    deinit {
        if task?.state == .running {
            task?.cancel()
        }
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
        if isStopped {
            tolog("canceled request")
            return
        }

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
                                 cachePolicy: parameters.cacheSettings.requestPolicy,
                                 timeoutInterval: parameters.timeoutInterval)
        request.httpMethod = parameters.method.toString()

        for (key, value) in parameters.header {
            request.addValue(value, forHTTPHeaderField: key)
        }

        if case .post(let body) = parameters.method {
            try body.fill(&request, isLoggingEnabled: parameters.isLoggingEnabled)
        }

        sdkRequest = request
    }
}

extension Request: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<Request: \(sdkRequest)>"
    }
}
