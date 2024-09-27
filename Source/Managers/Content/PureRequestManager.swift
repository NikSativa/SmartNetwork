import Foundation
import Threading

#if swift(>=6.0)
public protocol PureRequestManager: Sendable {
    typealias ResponseClosure = @Sendable (_ result: RequestResult) -> Void

    func map<T: CustomDecodable>(data: RequestResult,
                                 to type: T.Type,
                                 with parameters: Parameters) -> Result<T.Object, Error>

    func request(address: Address,
                 with parameters: Parameters,
                 inQueue completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> RequestingTask

    func request(address: Address,
                 with parameters: Parameters) async -> RequestResult
}
#else
public protocol PureRequestManager {
    typealias ResponseClosure = (_ result: RequestResult) -> Void

    func map<T: CustomDecodable>(data: RequestResult,
                                 to type: T.Type,
                                 with parameters: Parameters) -> Result<T.Object, Error>

    func request(address: Address,
                 with parameters: Parameters,
                 inQueue completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> RequestingTask

    func request(address: Address,
                 with parameters: Parameters) async -> RequestResult
}
#endif

public extension PureRequestManager {
    func request(address: Address,
                 with parameters: Parameters = .init(),
                 inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                 completion: @escaping ResponseClosure) -> RequestingTask {
        return request(address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    func request(address: Address,
                 with parameters: Parameters = .init()) async -> RequestResult {
        return await withCheckedContinuation { [self] completion in
            AsyncTaskHolder { holder in
                request(address: address,
                        with: parameters,
                        inQueue: .absent) { data in
                    holder.task = nil
                    completion.resume(returning: data)
                }
            }
        }
    }
}
