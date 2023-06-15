import Foundation
import NQueue

public protocol PureRequestManager {
    typealias ResponseClosure = (RequestResult) -> Void

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
            let task = request(address: address,
                               with: parameters,
                               inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            task.start()
        }
    }
}
