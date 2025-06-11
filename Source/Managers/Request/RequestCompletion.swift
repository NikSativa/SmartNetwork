import Foundation
import Threading

/// A protocol defining completion and async-handling behavior for network requests.
///
/// Conforming types provide mechanisms to complete requests either asynchronously using `async/await`,
/// or via closure-based completion handlers. Also supports one-way execution and optional error throwing.
public protocol RequestCompletion<Object> {
    associatedtype Object

    /// Asynchronously completes the request and returns the response object.
    ///
    /// - Returns: The result of the request, of type `Object`.
    @discardableResult
    func async() async -> Object

    /// A closure that receives the final response object.
    typealias CompletionClosure = (Object) -> Void

    /// Completes the request and delivers the result via a completion closure on the given queue.
    ///
    /// - Parameters:
    ///   - completionQueue: The queue on which to execute the completion.
    ///   - completion: A closure to handle the completed response.
    /// - Returns: A `SmartTasking` instance representing the running task.
    func complete(in completionQueue: DelayedQueue, completion: @escaping CompletionClosure) -> SmartTasking
}

public extension RequestCompletion {
    /// Completes the request on the default queue using a completion closure.
    ///
    /// - Parameter completion: A closure to handle the response.
    /// - Returns: A `SmartTasking` representing the request task.
    func complete(completion: @escaping CompletionClosure) -> SmartTasking {
        return complete(in: SmartNetworkSettings.defaultCompletionQueue, completion: completion)
    }

    /// Executes the request asynchronously without handling its result.
    ///
    /// Useful for fire-and-forget use cases. Automatically detaches and starts the task.
    ///
    /// - Returns: A detached task instance.
    @discardableResult
    func oneWay() -> DetachedTask {
        return complete(in: SmartNetworkSettings.defaultCompletionQueue) { _ in
            // nothing to do
        }
        .detach()
        .deferredStart()
    }

    /// Completes the request on the specified queue and invokes a `Void` closure after completion.
    ///
    /// - Parameters:
    ///   - completionQueue: The queue for executing the closure.
    ///   - completion: A closure to execute once the request completes.
    /// - Returns: A `SmartTasking` instance.
    func complete(in completionQueue: DelayedQueue = SmartNetworkSettings.defaultCompletionQueue,
                  completion: @escaping () -> Void) -> SmartTasking {
        return complete(in: completionQueue) { _ in
            completion()
        }
    }

    /// Asynchronously completes the request and either returns the success value or throws an error.
    ///
    /// - Throws: An error if the result is a failure.
    /// - Returns: The unwrapped success value of type `T`.
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
