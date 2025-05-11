import Combine
import Foundation
import Threading

/// A protocol representing a cancellable network task with optional detachment from request lifecycle.
///
/// `SmartTasking` (aka `SmartTask`) abstracts a unit of asynchronous work tied to a network request.
/// When the associated task is deallocated, the request is automatically cancelled unless detached.
/// This design enables concise integration with Combine or Swift Concurrency while preserving cancellation behavior.
///
/// - Note: This differs from `AnyCancellable`, which cancels the task upon deinitialization. Use `DetachedTask` when you need manual control over task lifecycle.
///
/// ```swift
/// // Prevent automatic cancellation by detaching from request lifecycle
/// SmartTask(runAction: {
///     print("Running a detached task")
/// })
/// .detach()        // Task will live independently of the request
/// .deferredStart() // Start the task later, or call `.start()` immediately
/// ```
public protocol SmartTasking: DetachedTask {
    /// Detaches the task from the request to prevent cancellation on deinitialization.
    ///
    /// - Important: When detached, the task will not cancel its associated request upon deallocation.
    /// - Note: This provides a self-retaining mechanism to avoid capturing the task in a separate variable.
    ///
    /// - Returns: The current instance of `DetachedTask`.
    @discardableResult
    func detach() -> DetachedTask
}
