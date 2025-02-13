import Combine
import Foundation
import Threading

@available(*, deprecated, renamed: "SmartRequest", message: "Use 'SmartRequest' instead.")
typealias Request = SmartRequest

internal struct SmartRequest {
    private let sessionAdaptor: SessionAdaptor
    private let address: Address

    let session: SmartURLSession
    let parameters: Parameters
    let userInfo: UserInfo
    let request: URLRequestRepresentation

    private var plugins: [Plugin] {
        return parameters.plugins
    }

    init(address: Address,
         parameters: Parameters,
         userInfo: UserInfo,
         urlRequestable: URLRequestRepresentation,
         session: SmartURLSession) {
        self.address = address
        self.parameters = parameters
        self.userInfo = userInfo
        self.request = urlRequestable
        self.session = session
        self.sessionAdaptor = .init(session: session, progressHandler: parameters.progressHandler)
    }

    private func startRealRequest() async throws -> SmartResponse {
        let sdkRequest = request.sdk
        if let stub = HTTPStubServer.shared.response(for: sdkRequest) {
            let response: URLResponse? = sdkRequest.url.map {
                return stub.urlResponse(url: $0)
            }
            let responseData = SmartResponse(request: request,
                                             body: stub.body?.data,
                                             response: response,
                                             error: stub.error,
                                             session: session)
            if let delay = stub.delayInSeconds, delay > 0 {
                try await Task.sleep(seconds: delay)
            }
            return responseData
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
                let responseData = SmartResponse(request: request,
                                                 body: cached.data,
                                                 response: cached.response,
                                                 error: nil,
                                                 session: session)
                return responseData
            }
        }

        let (data, response) = try await sessionAdaptor.dataTask(with: sdkRequest)
        try Task.checkCancellation()

        if let cacheSettings = parameters.cacheSettings {
            let cached = CachedURLResponse(response: response,
                                           data: data,
                                           userInfo: nil,
                                           storagePolicy: cacheSettings.storagePolicy)
            cacheSettings.cache.storeCachedResponse(cached, for: sdkRequest)
        }

        let responseData = SmartResponse(request: request,
                                         body: data,
                                         response: response,
                                         error: nil,
                                         session: session)

        return responseData
    }

    private func didReceiveNotification(_ data: SmartResponse) {
        for plugin in plugins {
            plugin.didReceive(parameters: parameters, userInfo: userInfo, request: request, data: data)
        }
    }

    private func notifyWillSend() {
        for plugin in plugins {
            plugin.willSend(parameters: parameters, userInfo: userInfo, request: request, session: session)
        }
    }

    private func notifyCancelation() {
        for plugin in plugins {
            plugin.wasCancelled(parameters: parameters, userInfo: userInfo, request: request, session: session)
        }
    }
}

extension SmartRequest {
    func start() async -> SmartResponse {
        do {
            return try await withTaskCancellationHandler {
                notifyWillSend()

                try Task.checkCancellation()

                let data = try await startRealRequest()

                try Task.checkCancellation()

                didReceiveNotification(data)

                return data
            } onCancel: {
                notifyCancelation()
                return
            }
        } catch {
            return .init(request: request,
                         body: nil,
                         response: nil,
                         error: error,
                         session: session)
        }
    }

    func cancel() {
        sessionAdaptor.stop()
        notifyCancelation()
    }
}

// MARK: - CustomDebugStringConvertible

extension SmartRequest: CustomDebugStringConvertible {
    var debugDescription: String {
        return makeDescription()
    }
}

// MARK: - CustomStringConvertible

extension SmartRequest: CustomStringConvertible {
    var description: String {
        return makeDescription()
    }
}

// MARK: - private

private final class SessionAdaptor {
    private let session: SmartURLSession
    private let progressHandler: ProgressHandler?
    private var task: URLSessionTask?
    private var observer: Any?

    required init(session: SmartURLSession,
                  progressHandler: ProgressHandler?) {
        self.session = session
        self.progressHandler = progressHandler
    }

    deinit {
        stop()
    }

    func dataTask(with request: URLRequest) async throws -> (Data, URLResponse) {
        stop()

        let (asyncBytes, response) = try await session.task(for: request)
        task = asyncBytes.task

        if let progressHandler = progressHandler,
           let task = task {
            observer = task.progress.observe(progressHandler)
        }

        var data = Data()

        for try await byte in asyncBytes {
            try Task.checkCancellation()
            data.append(byte)
        }

        return (data, response)
    }

    func stop() {
        if task?.state == .running {
            task?.cancel()
        }
        task = nil
        observer = nil
    }
}

private extension SmartRequest {
    func makeDescription() -> String {
        let url = try? address.url()
        let text = url?.absoluteString ?? "broken url"
        let method: String = (parameters.method ?? .other("`No method`")).toString()
        return "<\(method) request: \(text)" + (parameters.header.isEmpty ? "" : " headers: \(parameters.header)") + ">"
    }
}

#if swift(>=6.0)
extension SmartRequest: @unchecked Sendable {}
#endif

public extension Progress {
    func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return observe(\.fractionCompleted, changeHandler: { progress, _ in
            progressHandler(progress)
        })
    }
}
