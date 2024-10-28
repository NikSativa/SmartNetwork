import Combine
import Foundation
import Threading

/// ``SmartTasking``represents the ``SmartTask`` interface with the provided run and cancel actions.
/// _This is a Swift protocol designed to be mocked in unit tests._
///
/// - Important: ``SmartTask`` aka ``SmartTasking`` is designed to be attached to the request, which means request will be canceled when the task is deallocated.
/// - Note: Don't forget that ``AnyCancellable`` is cancelling the task on deinitialization.
///
/// ```swift
/// // Using `detached()` to prevent cancellation on deinitialization
/// SmartTask(runAction: {
///    print("Another task is running")
/// })
/// .detach() // detach the task from the request
/// .deferredStart() // or `start()`
/// ```
public protocol SmartTasking: DetachedTask {
    /// Detaches the task from the request to prevent cancellation on deinitialization.
    ///
    /// - Important: ``DetachedTask`` is designed to be detached from the request , which means request will not be canceled when the task is deallocated.
    /// - Note: In other words this is `Self-Retain` mechanism to avoid saving the task _(aka request)_ every time you don't want to create a variable for it.
    ///
    /// - Returns: The current instance of `DetachedTask`.
    @discardableResult
    func detach() -> DetachedTask
}
