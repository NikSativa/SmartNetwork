import Foundation
import Threading

/// A protocol that defines a completion handler for a request.
public protocol RequestCompletion<Object> {
    associatedtype Object

    /// Completes the request with the given completion closure.
    @discardableResult
    func async() async -> Object

    /// A closure that is called when a response is received.
    typealias CompletionClosure = (Object) -> Void

    /// Completes the request with the given completion closure.
    func complete(in completionQueue: DelayedQueue, completion: @escaping CompletionClosure) -> SmartTasking
}

public extension RequestCompletion {
    /// Completes the request with the given completion closure.
    func complete(completion: @escaping CompletionClosure) -> SmartTasking {
        return complete(in: SmartNetworkSettings.defaultCompletionQueue, completion: completion)
    }

    /// Completes the request without a completion and starts it asynchronously.
    @discardableResult
    func oneWay() -> DetachedTask {
        return complete(in: SmartNetworkSettings.defaultCompletionQueue) { _ in
            // nothing to do
        }
        .detach().deferredStart()
    }

    /// Completes the request with the given `Void` completion closure.
    func complete(in completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                  completion: @escaping () -> Void) -> SmartTasking {
        return complete(in: completionQueue) { _ in
            completion()
        }
    }

    /// Completes and start asynchronously the request with throwing error.
    @discardableResult
    func asyncWithThrowing<T>(_: T.Type = T.self) async throws -> T
    where Object == Result<T, Error> {
        let result = await async()
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
