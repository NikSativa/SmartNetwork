import Foundation
import Threading

#if swift(>=6.0)
/// A class that manages requests and responses for a ``RequestResult`` type.
public protocol PureRequestManager: Sendable {
    /// A closure that is called when a response is received.
    typealias ResponseClosure = @Sendable (_ result: RequestResult) -> Void

    /// Maps the given data to the specified type.
    func map<T: CustomDecodable>(data: RequestResult,
                                 to type: T.Type,
                                 with parameters: Parameters) -> Result<T.Object, Error>

    /// Sends a request to the specified address with the given parameters.
    func request(address: Address,
                 with parameters: Parameters,
                 inQueue completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking

    /// Sends a request to the specified address with the given parameters
    func request(address: Address,
                 with parameters: Parameters) async -> RequestResult
}
#else
/// A class that manages requests and responses for a ``RequestResult`` type.
public protocol PureRequestManager {
    typealias ResponseClosure = (_ result: RequestResult) -> Void

    /// Maps the given data to the specified type.
    func map<T: CustomDecodable>(data: RequestResult,
                                 to type: T.Type,
                                 with parameters: Parameters) -> Result<T.Object, Error>

    /// Sends a request to the specified address with the given parameters
    func request(address: Address,
                 with parameters: Parameters,
                 inQueue completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking

    /// Sends a request to the specified address with the given parameters
    func request(address: Address,
                 with parameters: Parameters) async -> RequestResult
}
#endif

public extension PureRequestManager {
    /// Sends a request to the specified address with the given parameters
    func request(address: Address,
                 with parameters: Parameters = .init(),
                 inQueue completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking {
        return request(address: address,
                       with: parameters,
                       inQueue: completionQueue,
                       completion: completion)
    }

    /// Sends a request to the specified address with the given parameters
    func request(address: Address,
                 with parameters: Parameters = .init()) async -> RequestResult {
        return await withCheckedContinuation { [self] completion in
            request(address: address,
                    with: parameters,
                    inQueue: .absent) { data in
                completion.resume(returning: data)
            }
            .detach().deferredStart()
        }
    }
}
