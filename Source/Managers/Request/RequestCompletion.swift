import Foundation
import Threading

/// A protocol that defines a completion handler for a request.
public protocol RequestCompletion<Object> {
    associatedtype Object

    /// A closure that is called when a response is received.
    typealias CompletionClosure = (Object) -> Void

    /// Completes the request with the given completion closure.
    func complete(in completionQueue: DelayedQueue, completion: @escaping CompletionClosure) -> SmartTasking
}

public extension RequestCompletion {
    /// Completes the request with the given completion closure.
    func complete(completion: @escaping CompletionClosure) -> SmartTasking {
        return complete(in: RequestSettings.defaultResponseQueue, completion: completion)
    }

    /// Completes the request without a completion.
    @discardableResult
    func oneWay() -> DetachedTask {
        return complete(in: RequestSettings.defaultResponseQueue) { _ in
            // nothing to do
        }
        .detach().deferredStart()
    }

    /// Completes the request with the given `Void` completion closure.
    func complete(in completionQueue: DelayedQueue = RequestSettings.defaultResponseQueue,
                  completion: @escaping () -> Void) -> SmartTasking {
        return complete(in: completionQueue) { _ in
            completion()
        }
    }

    /// Completes and start asynchronously the request.
    func async() async -> Object {
        return await withCheckedContinuation { continuation in
            complete(in: .absent) { result in
                let wrapped = USendable(result)
                continuation.resume(returning: wrapped.value)
            }
            .detach().deferredStart()
        }
    }

    /// Completes and start asynchronously the request with throwing error.
    func asyncWithThrowing<T>() async throws -> T
    where Object == Result<T, Error> {
        return try await withCheckedThrowingContinuation { continuation in
            complete(in: .absent) { result in
                let wrapped = USendable(result)
                continuation.resume(with: wrapped.value)
            }
            .detach().deferredStart()
        }
    }
}
