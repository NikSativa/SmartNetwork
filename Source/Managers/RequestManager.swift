import Foundation
import Threading

public final class RequestManager {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var state: State = .init()
    private let plugins: [Plugin]
    private let stopTheLine: StopTheLine?
    private let maxAttemptNumber: Int

    public init(withPlugins plugins: [Plugin] = [],
                stopTheLine: StopTheLine? = nil,
                maxAttemptNumber: Int = 1) {
        self.plugins = plugins
        self.stopTheLine = stopTheLine
        self.maxAttemptNumber = max(maxAttemptNumber, 1)
    }

    // MARK: - ivars

    public var pure: PureRequestManager {
        return self
    }

    public var decodable: DecodableRequestManager {
        return self
    }

    public func custom<T: CustomDecodable>(_ type: T.Type) -> TypedRequestManager<T.Object> {
        return TypedRequestManager(type, parent: self)
    }

    public private(set) lazy var void: TypedRequestManager<Void> = {
        return custom(VoidContent.self)
    }()

    public private(set) lazy var data: TypedRequestManager<Data> = {
        return custom(DataContent.self)
    }()

    public private(set) lazy var dataOptional: TypedRequestManager<Data?> = {
        return custom(OptionalDataContent.self)
    }()

    public private(set) lazy var image: TypedRequestManager<Image> = {
        return custom(ImageContent.self)
    }()

    public private(set) lazy var imageOptional: TypedRequestManager<Image?> = {
        return custom(OptionalImageContent.self)
    }()

    public private(set) lazy var json: TypedRequestManager<Any> = {
        return custom(JSONContent.self)
    }()

    public private(set) lazy var jsonOptional: TypedRequestManager<Any?> = {
        return custom(OptionalJSONContent.self)
    }()

    // MARK: -

    private func unfreeze() {
        let scheduledRequests = $state.mutate { state in
            state.isRunning = true
            return state.tasksQueue
        }

        for request in scheduledRequests {
            request.value.request.start()
        }
    }

    private func makeStopTheLineAction(stopTheLine: StopTheLine,
                                       info: Info,
                                       data: RequestResult) {
        let newFactory = RequestManager(withPlugins: plugins,
                                        stopTheLine: nil,
                                        maxAttemptNumber: maxAttemptNumber)
        stopTheLine.action(with: newFactory,
                           originalParameters: info.request.parameters,
                           response: data,
                           userInfo: info.userInfo) { [self] result in
            switch result {
            case .useOriginal:
                complete(with: data, for: info)
            case .passOver(let newResponse):
                complete(with: newResponse, for: info)
            case .retry:
                break
            }
            unfreeze()
        }
    }

    private func checkStopTheLine(_ result: RequestResult,
                                  info: Info) -> Bool {
        guard let stopTheLine else {
            return true
        }

        let verificationResult = stopTheLine.verify(response: result,
                                                    for: info.parameters,
                                                    userInfo: info.userInfo)
        switch verificationResult {
        case .stopTheLine:
            if state.isRunning {
                state.isRunning = false
            }
            makeStopTheLineAction(stopTheLine: stopTheLine,
                                  info: info,
                                  data: result)
            return false
        case .passOver:
            return true
        case .retry:
            if info.attemptNumber < maxAttemptNumber {
                info.attemptNumber += 1
                info.request.start()
                return false
            }
            return true
        }
    }

    private func tryComplete(with result: RequestResult,
                             for info: Info) {
        guard checkStopTheLine(result, info: info) else {
            return
        }

        complete(with: result, for: info)
    }

    private func complete(with result: RequestResult,
                          for info: Info) {
        let userInfo = info.userInfo
        let plugins = info.parameters.plugins
        do {
            for plugin in plugins {
                try plugin.verify(data: result, userInfo: userInfo)
            }
        } catch {
            result.set(error)
        }

        $state.mutate {
            $0.tasksQueue[info.key] = nil
        }

        let completion = info.completion
        completion(result, userInfo, plugins)
    }

    private func createRequest(address: Address,
                               with parameters: Parameters,
                               userInfo: UserInfo) throws -> Requestable {
        var urlRequest = try parameters.urlRequest(for: address)
        for plugin in parameters.plugins {
            plugin.prepare(parameters,
                           request: &urlRequest)
        }

        let request = Request.create(address: address,
                                     with: parameters,
                                     urlRequestable: urlRequest)
        return request
    }

    private func prepare(_ parameters: Parameters) -> Parameters {
        if plugins.isEmpty {
            return parameters
        }

        var plugins = parameters.plugins
        plugins += self.plugins
        plugins = plugins.unified()

        var newParameters = parameters
        newParameters.plugins = plugins
        return newParameters
    }
}

extension RequestManager: RequestManagering {}

// MARK: - PureRequestManager

extension RequestManager: PureRequestManager {
    public func map<T: CustomDecodable>(data: RequestResult,
                                        to type: T.Type,
                                        with parameters: Parameters) -> Result<T.Object, Error> {
        let result = type.decode(with: data, decoder: parameters.decoder)
        switch result {
        case .success:
            data.set(nil)
        case .failure(let error):
            data.set(error)
        }

        return result
    }

    public func request(address: Address,
                        with parameters: Parameters,
                        inQueue completionQueue: DelayedQueue,
                        completion: @escaping PureRequestManager.ResponseClosure) -> RequestingTask {
        let parameters = prepare(parameters)
        do {
            let request = try createRequest(address: address,
                                            with: parameters,
                                            userInfo: parameters.userInfo)
            let info: Info = .init(parameters: parameters,
                                   request: request) { result, userInfo, plugins in
                for plugin in plugins {
                    plugin.didFinish(withData: result, userInfo: userInfo)
                }

                completionQueue.fire {
                    completion(result)
                }
            }
            $state.mutate {
                $0.tasksQueue[info.key] = info
            }

            request.completion = { [weak self, weak info] result in
                guard let self, let info else {
                    return
                }
                tryComplete(with: result, for: info)
            }

            return RequestingTask(runAction: { [state] in
                if state.isRunning {
                    request.start()
                }
            }, cancelAction: { [request] in
                request.cancel()
            })
        } catch {
            return RequestingTask(runAction: {
                let result = RequestResult(request: nil, body: nil, response: nil, error: error)
                completion(result)
            })
        }
    }
}

// MARK: - DecodableRequestManager

#if swift(>=6.0)
extension RequestManager: DecodableRequestManager {
    public func request<T>(opt type: T.Type,
                           address: Address,
                           with parameters: Parameters,
                           inQueue completionQueue: DelayedQueue,
                           completion: @escaping @Sendable (Result<T?, Error>) -> Void) -> RequestingTask
    where T: Decodable & Sendable {
        return request(address: address,
                       with: parameters,
                       inQueue: completionQueue) { [self] data in
            let result = map(data: data, to: OptionalDecodableContent<T>.self, with: parameters)
            completionQueue.fire {
                completion(result)
            }
        }
    }

    public func request<T>(_ type: T.Type,
                           address: Address,
                           with parameters: Parameters,
                           inQueue completionQueue: Threading.DelayedQueue,
                           completion: @escaping @Sendable (Result<T, Error>) -> Void) -> RequestingTask
    where T: Decodable & Sendable {
        return request(address: address,
                       with: parameters,
                       inQueue: completionQueue) { [self] data in
            let result = map(data: data, to: DecodableContent<T>.self, with: parameters)
            completionQueue.fire {
                completion(result)
            }
        }
    }
}
#else
extension RequestManager: DecodableRequestManager {
    public func request<T>(opt type: T.Type,
                           address: Address,
                           with parameters: Parameters,
                           inQueue completionQueue: DelayedQueue,
                           completion: @escaping (Result<T?, Error>) -> Void) -> RequestingTask
    where T: Decodable {
        return request(address: address,
                       with: parameters,
                       inQueue: completionQueue) { [self] data in
            let result = map(data: data, to: OptionalDecodableContent<T>.self, with: parameters)
            completionQueue.fire {
                completion(result)
            }
        }
    }

    public func request<T>(_ type: T.Type,
                           address: Address,
                           with parameters: Parameters,
                           inQueue completionQueue: Threading.DelayedQueue,
                           completion: @escaping (Result<T, Error>) -> Void) -> RequestingTask
    where T: Decodable {
        return request(address: address,
                       with: parameters,
                       inQueue: completionQueue) { [self] data in
            let result = map(data: data, to: DecodableContent<T>.self, with: parameters)
            completionQueue.fire {
                completion(result)
            }
        }
    }
}
#endif

public extension RequestManager {
    /// creates protocol wrapped interface instead of concrete realization
    /// let manager: RequestManagering = RequestManager()
    /// vs
    /// let manager = RequestManager.create()
    static func create(withPlugins plugins: [Plugin] = [],
                       stopTheLine: StopTheLine? = nil,
                       maxAttemptNumber: Int = 1) -> RequestManagering {
        return Self(withPlugins: plugins,
                    stopTheLine: stopTheLine,
                    maxAttemptNumber: maxAttemptNumber)
    }
}

// MARK: - private

private extension RequestManager {
    typealias Key = ObjectIdentifier
    #if swift(>=6.0)
    typealias ResponseClosureWithInfo = @Sendable (_ result: RequestResult, _ userInfo: UserInfo, _ plugins: [Plugin]) -> Void
    #else
    typealias ResponseClosureWithInfo = (_ result: RequestResult, _ userInfo: UserInfo, _ plugins: [Plugin]) -> Void
    #endif

    final class Info {
        let key: Key
        let parameters: Parameters
        let request: Requestable
        let completion: ResponseClosureWithInfo
        #if swift(>=6.0)
        nonisolated(unsafe) var attemptNumber: Int
        #else
        var attemptNumber: Int
        #endif

        var userInfo: UserInfo {
            return parameters.userInfo
        }

        init(parameters: Parameters,
             request: Requestable,
             completion: @escaping ResponseClosureWithInfo) {
            self.key = Key(request)
            self.parameters = parameters
            self.request = request
            self.completion = completion
            self.attemptNumber = 0
        }
    }

    final class State {
        var isRunning: Bool = true
        var tasksQueue: [Key: Info] = [:]
    }
}

#if swift(>=6.0)
extension RequestManager: @unchecked Sendable {}
extension RequestManager.Info: Sendable {}
extension RequestManager.State: @unchecked Sendable {}
#endif
