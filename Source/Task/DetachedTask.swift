import Combine
import Foundation
import Threading

/// A protocol representing a cancellable asynchronous task with flexible lifecycle control.
///
/// `DetachedTask` encapsulates execution and cancellation behavior for tasks tied to request lifecycles.
/// It extends `Cancellable` and adds support for immediate or deferred execution, providing control over when
/// and how a task is started. Unlike `AnyCancellable`, it supports detachment to avoid automatic cancellation
/// on deallocation.
///
/// - Important: When using `DetachedTask`, the associated request will not be automatically cancelled when the task is deallocated.
/// - Note: This differs from `AnyCancellable`, which cancels the task upon deinitialization. Use `DetachedTask` when you need manual control over task lifecycle.
public protocol DetachedTask: Cancellable, CustomDebugStringConvertible, CustomStringConvertible, SmartSendable {
    /// Metadata storage associated with the task.
    ///
    /// Use this to store custom context like identifiers, retry counts, or diagnostic values.
    /// You can also access `.smartTaskRequestAddressKey` to determine the associated request.
    var userInfo: UserInfo { get }

    /// Starts the task immediately.
    func start()

    /// Schedules the task to start asynchronously on the specified queue.
    ///
    /// - Parameter queue: The queue on which to execute the task.
    /// - Returns: The current task instance.
    @discardableResult
    func deferredStart(in queue: Queueable) -> Self

    /// Schedules the task to start on the default queue defined in `RequestSettings.defferedStartQueue`.
    ///
    /// - Returns: The current task instance.
    @discardableResult
    func deferredStart() -> Self
}

public extension DetachedTask {
    var description: String {
        return userInfo.description
    }

    var debugDescription: String {
        return userInfo.debugDescription
    }
}
