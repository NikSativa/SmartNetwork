import Foundation
import Threading

#if swift(>=6.0)
open class TypedRequestManager<Response>: @unchecked Sendable {
    private let requestTask: (_ address: Address,
                              _ parameters: Parameters,
                              _ completionQueue: Threading.DelayedQueue,
                              _ seflRetain: Bool,
                              _ completion: @escaping @Sendable (Result<Response, Error>) -> Void) -> RequestingTask

    public required init<Content: CustomDecodable>(_ type: Content.Type, parent: PureRequestManager)
        where Response == Content.Object {
        self.requestTask = { [parent] address, parameters, completionQueue, _, completion in
            return parent.request(address: address,
                                  with: parameters,
                                  inQueue: completionQueue) { [parent] data in
                let result = parent.map(data: data, to: Content.self, with: parameters)
                let sendable = UnSendable(result)
                completionQueue.fire {
                    completion(sendable.value)
                }
            }
        }
    }

    open func request(address: Address,
                      with parameters: Parameters = .init(),
                      inQueue completionQueue: Threading.DelayedQueue = RequestSettings.defaultResponseQueue,
                      completion: @escaping @Sendable (Result<Response, Error>) -> Void) -> RequestingTask {
        return requestTask(address,
                           parameters,
                           completionQueue,
                           false,
                           completion)
    }

    open func request(address: Address,
                      with parameters: Parameters = .init()) async -> Result<Response, Error>
    where Response: Sendable {
        return await withCheckedContinuation { [self] completion in
            requestTask(address,
                        parameters,
                        .absent,
                        false) { data in
                completion.resume(returning: data)
            }
            .autorelease().deferredStart()
        }
    }

    open func requestWithThrowing(address: Address,
                                  with parameters: Parameters = .init()) async throws -> Response
    where Response: Sendable {
        return try await withCheckedThrowingContinuation { [self] completion in
            requestTask(address,
                        parameters,
                        .absent,
                        false) { data in
                completion.resume(with: data)
            }
            .autorelease().deferredStart()
        }
    }
}
#else
open class TypedRequestManager<Response> {
    private let requestTask: (_ address: Address,
                              _ parameters: Parameters,
                              _ completionQueue: Threading.DelayedQueue,
                              _ seflRetain: Bool,
                              _ completion: @escaping (Result<Response, Error>) -> Void) -> RequestingTask

    public required init<Content: CustomDecodable>(_ type: Content.Type, parent: PureRequestManager)
        where Response == Content.Object {
        self.requestTask = { [parent] address, parameters, completionQueue, _, completion in
            return parent.request(address: address,
                                  with: parameters,
                                  inQueue: completionQueue) { [parent] data in
                let result = parent.map(data: data, to: Content.self, with: parameters)
                completionQueue.fire {
                    completion(result)
                }
            }
        }
    }

    open func request(address: Address,
                      with parameters: Parameters = .init(),
                      inQueue completionQueue: Threading.DelayedQueue = RequestSettings.defaultResponseQueue,
                      completion: @escaping (Result<Response, Error>) -> Void) -> RequestingTask {
        return requestTask(address,
                           parameters,
                           completionQueue,
                           false,
                           completion)
    }

    open func request(address: Address,
                      with parameters: Parameters = .init()) async -> Result<Response, Error> {
        return await withCheckedContinuation { [self] completion in
            requestTask(address,
                        parameters,
                        .absent,
                        false) { data in
                completion.resume(returning: data)
            }
            .autorelease().deferredStart()
        }
    }

    open func requestWithThrowing(address: Address,
                                  with parameters: Parameters = .init()) async throws -> Response {
        return try await withCheckedThrowingContinuation { [self] completion in
            requestTask(address,
                        parameters,
                        .absent,
                        false) { data in
                completion.resume(with: data)
            }
            .autorelease().deferredStart()
        }
    }
}
#endif
