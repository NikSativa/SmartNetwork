import Combine
import Foundation
import Threading

/// RequestingTask is a Swift class designed to manage tasks related to requests efficiently.
/// It encapsulates the execution and cancellation actions associated with a task,
/// providing a convenient way to handle these operations within the context of request management.
///
/// ```swift
/// // Creating a RequestingTask instance with a run action
/// let task = RequestingTask(runAction: {
///    print("Task is running")
/// }, cancelAction: {
///    print("Task is canceled")
/// })
/// task.start()
///
/// // Using autorelease to prevent cancellation on deinitialization and start action on the next MainQueue cycle
/// RequestingTask(runAction: {
///    print("Another task is running")
/// }).autorelease().deferredStart(in: Queue.main)
/// ```
public final class RequestingTask {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var cancelAction: (() -> Void)?

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var runAction: (() -> Void)?

    private var shouldCancelOnDeinit: Bool = true

    /// Initializes a RequestingTask instance with the provided run and cancel actions.
    ///
    /// * Parameters:
    ///   - runAction: The action to be executed when the task runs.
    ///   - cancelAction: The action to be performed when the task is canceled (optional).
    public init(runAction: @escaping () -> Void,
                cancelAction: (() -> Void)? = nil) {
        self.runAction = runAction
        self.cancelAction = cancelAction
    }

    /// Self-Retain to avoid saving the request every time you don't want to create a variable for it
    /// Prevents the task from being canceled on deinitialization by setting shouldCancelOnDeinit to false.
    ///
    /// - Returns: The current instance of RequestingTask.
    @discardableResult
    public func autorelease() -> Self {
        shouldCancelOnDeinit = false
        return self
    }

    deinit {
        if shouldCancelOnDeinit {
            cancelAction?()
        }
    }
}

public extension RequestingTask {
    /// Start the task immediately
    func start() {
        precondition(runAction != nil, "should be called only once")
        let runAction = runAction
        self.runAction = nil
        runAction?()
    }

    /// Start the task after on the next run loop cycle
    @discardableResult
    func deferredStart(in queue: Queueable = RequestSettings.defferedStartQueue) -> Self {
        queue.async { [self] in
            start()
        }
        return self
    }

    /// Cancel the task immediately
    func cancel() {
        runAction = nil

        let cancelAction = cancelAction
        self.cancelAction = nil
        cancelAction?()
    }
}

// MARK: - Cancellable

extension RequestingTask: Cancellable {
    /// only for the convenience of the Combine interface
    /// e.g. manager.request(with: parameters).deferredStart().store(in: &bag)
    public func toAny() -> AnyCancellable {
        return AnyCancellable(cancel)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func storing<C>(in collection: inout C) -> Self
    where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        store(in: &collection)
        return self
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func storing(in set: inout Set<AnyCancellable>) -> Self {
        store(in: &set)
        return self
    }
}

#if swift(>=6.0)
extension RequestingTask: @unchecked Sendable {}
#endif
