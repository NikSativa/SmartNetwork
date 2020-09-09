import Foundation

class Request<R: InternalDecodable>: Requestable {
    typealias ResponseType = R.Response

    private var completeCallback: CompleteCallback?
    func onComplete(_ callback: @escaping CompleteCallback) {
        completeCallback = callback
    }

    // MARK: -
    private var task: URLSessionDataTask?
    private var sdkRequest: URLRequest
    private var isStopped: Bool = false

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

        task = Configuration.session.dataTask(with: sdkRequest) { [weak self] (data, response, error) -> Void in
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

            self.fire(data: data, response: response, error: error)
            self.task = nil
        }

        task?.resume()
    }

    func stop() {
        isStopped = true

        task?.cancel()
        task = nil

        plugins.forEach {
            $0.didStop(info)
        }
    }

    deinit {
        task?.cancel()
        task = nil
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

    private func fire(data: Data?, response: URLResponse?, error: Error?) {
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

        do {
            var modifiedData: Data?
            if var tData = data {
                plugins.forEach {
                    tData = $0.map(data: tData)
                }
                modifiedData = tData
            }

            tolog({
                let obj = { try? JSONSerialization.jsonObject(with: modifiedData ?? Data(), options: JSONSerialization.ReadingOptions())}
                return "response: " + (String(data: modifiedData ?? Data(), encoding: .utf8) ?? obj().map({ String(describing: $0) }) ?? "nil")
                }())

            try plugins.forEach {
                try $0.verify(httpStatusCode: httpStatusCode, header: header, data: modifiedData, error: error)
            }

            let response = try R(with: modifiedData)
            parameters.queue.async {
                self.completeCallback?(.success(response.content))

                self.plugins.forEach {
                    $0.didComplete(self.info, response: response.content, error: nil)
                }
            }
        } catch let resultError {
            let completionHandler = { [weak self] in
                guard let self = self else {
                    return
                }

                self.parameters.queue.async {
                    self.tolog("failed request: \(resultError)")
                    self.completeCallback?(.failure(resultError))

                    self.plugins.forEach {
                        $0.didComplete(self.info, response: nil, error: resultError)
                    }
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
        return "<Request: \(sdkRequest)"
    }
}
