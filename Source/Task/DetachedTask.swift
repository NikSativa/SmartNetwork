import Combine
import Foundation
import Threading

/// `DetachedTask` is a Swift protocol designed to manage tasks related to requests efficiently.
/// It encapsulates the execution and cancellation actions associated with a task, providing a convenient way to handle these operations within the context of request management.
/// The protocol extends the `Cancellable` protocol, which provides the ability to cancel the task.
/// The protocol also provides methods to start the task immediately or schedule it to start in a specific queue.
/// - Important: `DetachedTask` is designed to be detached from the request, which means request will not be canceled when the task is deallocated.
public protocol DetachedTask: Cancellable {
    /// Start the task immediately
    func start()

    /// Schedule the task to start in the specified queue
    @discardableResult
    func deferredStart(in queue: Queueable) -> Self

    /// Start the task in the `RequestSettings.defferedStartQueue`
    @discardableResult
    func deferredStart() -> Self

    /// Cancel the task immediately
    func cancel()
}

public extension DetachedTask {
    func toAny() -> AnyCancellable {
        return AnyCancellable(cancel)
    }

    /// Stores this cancellable instance in the specified collection.
    ///
    /// Only for the convenience of the Combine interface
    /// e.g. manager.request(with: parameters).storing(in: &bag).start()
    ///
    /// - Parameter collection: The collection in which to store this ``Cancellable``.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func storing<C>(in collection: inout C) -> Self
    where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        store(in: &collection)
        return self
    }

    /// Stores this cancellable instance in the specified set.
    ///
    /// Only for the convenience of the Combine interface
    /// e.g. manager.request(with: parameters).storing(in: &bag).start()
    ///
    /// - Parameter set: The set in which to store this ``Cancellable``.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func storing(in set: inout Set<AnyCancellable>) -> Self {
        store(in: &set)
        return self
    }
}
