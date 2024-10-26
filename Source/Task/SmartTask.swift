import Combine
import Foundation
import Threading

/// `SmartTask` is a Swift protocol designed to manage tasks related to requests efficiently.
/// It encapsulates the execution and cancellation actions associated with a request,
/// providing a convenient way to handle these operations within the context of request management.
///
/// - Important: `SmartTask` is designed to be attached to the request, which means request will be canceled when the task is deallocated.
///
/// ```swift
/// // Creating a RequestingTask instance with a run action
/// let task = SmartTask(runAction: {
///    print("Task is running")
/// }, cancelAction: {
///    print("Task is canceled")
/// })
/// task.start()
///
/// // Using `detached()` to prevent cancellation on deinitialization
/// SmartTask(runAction: {
///    print("Another task is running")
/// })
/// .detached() // detach the task from the request
/// .deferredStart() // or `start()`
/// ```
public final class SmartTask {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var cancelAction: (() -> Void)?

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var runAction: (() -> Void)?

    private var shouldCancelOnDeinit: Bool = true

    /// Initializes a SmartTask instance with the provided run and cancel actions.
    ///
    /// * Parameters:
    ///   - runAction: The action to be executed when the task runs.
    ///   - cancelAction: The action to be performed when the task is canceled (optional).
    public init(runAction: @escaping () -> Void,
                cancelAction: (() -> Void)? = nil) {
        self.runAction = runAction
        self.cancelAction = cancelAction
    }

    deinit {
        if shouldCancelOnDeinit {
            cancelAction?()
        }
    }
}

// MARK: - RequestingTask

extension SmartTask: RequestingTask {
    @discardableResult
    public func detached() -> DetachedTask {
        shouldCancelOnDeinit = false
        return self
    }
}

// MARK: - DetachedTask

extension SmartTask: DetachedTask {
    public func start() {
        precondition(runAction != nil, "should be called only once")
        let runAction = runAction
        self.runAction = nil
        runAction?()
    }

    @discardableResult
    public func deferredStart(in queue: Queueable) -> Self {
        queue.async { [self] in
            start()
        }
        return self
    }

    @discardableResult
    public func deferredStart() -> Self {
        RequestSettings.defferedStartQueue.async { [self] in
            start()
        }
        return self
    }

    public func cancel() {
        runAction = nil

        let cancelAction = cancelAction
        self.cancelAction = nil
        cancelAction?()
    }
}

#if swift(>=6.0)
extension SmartTask: @unchecked Sendable {}
#endif