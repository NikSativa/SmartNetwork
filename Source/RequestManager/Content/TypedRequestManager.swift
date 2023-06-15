import Foundation
import NQueue

public struct TypedRequestManager<Response> {
    private let requestTask: (_ address: Address,
                              _ parameters: Parameters,
                              _ completionQueue: NQueue.DelayedQueue,
                              _ completion: @escaping (Result<Response, Error>) -> Void) -> RequestingTask

    init<Content: CustomDecodable>(_ type: Content.Type, parent: PureRequestManager)
        where Response == Content.Object {
        self.requestTask = { [parent] address, parameters, completionQueue, completion in
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

    public func request(address: Address,
                        with parameters: Parameters = .init(),
                        inQueue completionQueue: NQueue.DelayedQueue = RequestSettings.defaultResponseQueue,
                        completion: @escaping (Result<Response, Error>) -> Void) -> RequestingTask {
        return requestTask(address,
                           parameters,
                           completionQueue,
                           completion)
    }

    public func request(address: Address,
                        with parameters: Parameters) async -> Result<Response, Error> {
        return await withCheckedContinuation { [self] completion in
            let task = request(address: address,
                               with: parameters,
                               inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            task.start()
        }
    }

    public func request(address: Address,
                        with parameters: Parameters) async throws -> Response {
        return try await withCheckedThrowingContinuation { [self] completion in
            let task = request(address: address,
                               with: parameters,
                               inQueue: .absent) { data in
                completion.resume(with: data)
            }
            task.start()
        }
    }
}
