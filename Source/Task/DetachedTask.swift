import Combine
import Foundation
import Threading

/// ``DetachedTask`` is a Swift protocol designed to manage tasks related to requests efficiently.
/// It encapsulates the execution and cancellation actions associated with a task, providing a convenient way to handle these operations within the context of request management.
/// The protocol extends the ``Cancellable`` protocol, which provides the ability to cancel the task.
/// The protocol also provides methods to start the task immediately or schedule it to start in a specific queue.
///
/// - Important: ``DetachedTask`` is designed to be detached from the request, which means request will not be canceled when the task is deallocated.
/// - Note: Don't forget that ``AnyCancellable`` is cancelling the task on deinitialization.
public protocol DetachedTask: Cancellable, CustomDebugStringConvertible, CustomStringConvertible {
    /// The user information associated with the task.
    ///
    /// - Note: you can use the ``.smartTaskRequestAddressKey`` key to determine which request the task belongs to.
    var userInfo: UserInfo { get }

    /// Start the task immediately
    func start()

    /// Schedule the task to start in the specified queue
    @discardableResult
    func deferredStart(in queue: Queueable) -> Self

    /// Start the task in the `RequestSettings.defferedStartQueue`
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
