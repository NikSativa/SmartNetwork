import Foundation

/// `RequestingTask` is a Swift protocol designed to be mocked in unit tests.
/// It represents the `SmartTask` interface with the provided run and cancel actions.
///
/// - Important: `SmartTask` aka `RequestingTask` is designed to be attached to the request, which means request will be canceled when the task is deallocated.
///
/// ```swift
/// // Using `detached()` to prevent cancellation on deinitialization
/// SmartTask(runAction: {
///    print("Another task is running")
/// })
/// .detached() // detach the task from the request
/// .deferredStart() // or `start()`
/// ```
public protocol RequestingTask: DetachedTask {
    /// Detaches the task from the request to prevent cancellation on deinitialization.
    ///
    /// - Important: `DetachedTask` is designed to be detached from the request , which means request will not be canceled when the task is deallocated.
    /// - Note: In other words this is `Self-Retain` mechanism to avoid saving the task(aka request) every time you don't want to create a variable for it.
    ///
    /// - Returns: The current instance of `DetachedTask`.
    @discardableResult
    func detached() -> DetachedTask
}
