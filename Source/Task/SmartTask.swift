import Combine
import Foundation
import Threading

/// A lightweight task manager for request execution and cancellation, conforming to `SmartTasking` and `DetachedTask`.
///
/// `SmartTask` encapsulates task lifecycle operations, including immediate or deferred execution and automatic or manual cancellation.
/// By default, it mimics `AnyCancellable` by canceling the task when deallocated—unless explicitly detached via `detach()`.
///
/// Use this class to manage request-bound asynchronous work in a way that is composable, testable, and memory-safe.
public final class SmartTask {
    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var cancelAction: (() -> Void)?

    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var runAction: (() -> Void)?

    @Atomic(mutex: AnyMutex.pthread(.recursive), read: .sync, write: .sync)
    private var shouldCancelOnDeinit: Bool = true

    /// Arbitrary metadata associated with the task.
    ///
    /// Can be used to store request identifiers, retry counts, or custom diagnostics.
    public lazy var userInfo: UserInfo = .init()

    /// Creates a new `SmartTask` with the specified execution and cancellation behavior.
    ///
    /// - Parameters:
    ///   - runAction: The closure to execute when the task is started.
    ///   - cancelAction: An optional closure to execute if the task is cancelled.
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

// MARK: - SmartTasking

extension SmartTask: SmartTasking {
    /// Detaches the task from its cancellation-on-deinit behavior.
    ///
    /// Calling this prevents the task from being automatically cancelled when deallocated.
    /// Returns the instance for chaining.
    @discardableResult
    public func detach() -> DetachedTask {
        shouldCancelOnDeinit = false
        return self
    }
}

// MARK: - DetachedTask

extension SmartTask: DetachedTask {
    /// Executes the task immediately on the current thread, if not already started.
    public func start() {
        let runAction = $runAction.mutate { runAction in
            let action = runAction
            runAction = nil
            return action
        }
        runAction?()
    }

    /// Schedules the task to execute on the provided queue.
    ///
    /// - Parameter queue: The execution queue.
    /// - Returns: The current task instance.
    @discardableResult
    public func deferredStart(in queue: Queueable) -> Self {
        queue.async { [self] in
            start()
        }
        return self
    }

    /// Schedules the task to execute on the default deferred queue defined in `SmartNetworkSettings`.
    ///
    /// - Returns: The current task instance.
    @discardableResult
    public func deferredStart() -> Self {
        SmartNetworkSettings.deferredStartQueue.async { [self] in
            start()
        }
        return self
    }
}

// MARK: - Cancellable

extension SmartTask: Cancellable {
    /// Cancels the task and clears associated actions to release resources.
    public func cancel() {
        runAction = nil

        let cancelAction = $cancelAction.mutate { cancelAction in
            let action = cancelAction
            cancelAction = nil
            return action
        }
        cancelAction?()
    }
}

#if swift(>=6.0)
extension SmartTask: @unchecked Sendable {}
#endif
