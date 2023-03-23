import Foundation
import NQueue


public protocol Request: AnyObject {
    typealias CompletionCallback = (ResponseData) -> Void
    var completion: CompletionCallback? { get set }

    var userInfo: Parameters.UserInfo { get set }
    var parameters: Parameters { get }

    func cancel()
    func start()
}

// MARK: - Impl.Request

extension Impl {
    final class Request {
        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
        private var sessionAdaptor: SessionAdaptor?
        private var isCanceled: Bool = false
        private let pluginContext: PluginProvider
        private(set) var parameters: Parameters

        @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
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
                                        error: error)
                complete(in: parameters.queue,
                         with: data)
            }
        }

        private func start(with requestable: NRequest.URLRequestable) {
            plugins.forEach {
                $0.willSend(parameters,
                            request: requestable,
                            userInfo: &userInfo)
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
                                                    error: nil)
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

                self.sessionAdaptor?.clear()
                self.sessionAdaptor = nil

                self.tologSelf(sdkRequest)

                let responseData = ResponseData(request: requestable,
                                                body: data,
                                                response: response,
                                                error: error)

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
            tolog(data.body, allHTTPHeaderFields: sdkRequest.allHTTPHeaderFields)

            for plugin in plugins {
                do {
                    try plugin.verify(data: data,
                                      userInfo: &userInfo)
                } catch let catchedError {
                    self.tolog {
                        return "failed request: \(catchedError)"
                    }
                    data.error = catchedError
                }
            }

            plugins.forEach {
                $0.didReceive(parameters,
                              data: data,
                              userInfo: &userInfo)
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

// MARK: - Impl.Request + Request

extension Impl.Request: Request {
    var userInfo: Parameters.UserInfo {
        get {
            return parameters.userInfo
        }
        set {
            parameters.userInfo = newValue
        }
    }

    func start() {
        startRealRequest()
    }

    func cancel() {
        isCanceled = true
        stopSessionRequest()
    }
}

extension Impl.Request {
    private func tolog(file: String = #file,
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

    private func tologSelf(_ modifiedRequest: URLRequest,
                           file: String = #file,
                           method: String = #function,
                           line: Int = #line) {
        tolog(file: file,
              method: method,
              line: line) {
            return [
                "<with headers:",
                modifiedRequest.allHTTPHeaderFields.postmanFormat,
                ">"
            ].joined(separator: "\n")
        }
    }

    private func tolog(_ data: Data?,
                       allHTTPHeaderFields: [String: String]?,
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
            allHTTPHeaderFields.postmanFormat,
            ">",
            text
        ].joined(separator: "\n"),
        file: file,
        method: method,
        line: line)
    }
}

// MARK: - Impl.Request + CustomDebugStringConvertible, CustomStringConvertible

extension Impl.Request: CustomDebugStringConvertible, CustomStringConvertible {
    private func makeDescription() -> String {
        let url = try? parameters.address.url(shouldAddSlashAfterEndpoint: parameters.shouldAddSlashAfterEndpoint)
        let text = url?.absoluteString ?? "broken url"
        return "<\(parameters.method.toString()) request: \(text)>"
    }

    var debugDescription: String {
        return makeDescription()
    }

    var description: String {
        return makeDescription()
    }
}

private final class SessionAdaptor: NSObject {
    private let parameters: Parameters
    private var invalidator: (() -> Void)?

    private lazy var session: Session = {
        return parameters.session
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
            observer = newTask.observe(progressHandler)
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
        let url = try address.url(shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint)
        var request = URLRequest(url: url,
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method.toString()

        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }

        try body.fill(&request, isLoggingEnabled: isLoggingEnabled)

        return request
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
