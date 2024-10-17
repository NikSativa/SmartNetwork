import Combine
import Foundation
import Threading

public final class RequestingTask {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var cancelAction: (() -> Void)?

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var runAction: (() -> Void)?

    private var shouldCancelOnDeinit: Bool = true

    public init(runAction: @escaping () -> Void,
                cancelAction: (() -> Void)? = nil) {
        self.runAction = runAction
        self.cancelAction = cancelAction
    }

    /// Self-Retain to avoid saving the request every time you don't want to create a variable for it
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
    func start() {
        precondition(runAction != nil, "should be called only once")
        let runAction = runAction
        self.runAction = nil
        runAction?()
    }

    @discardableResult
    func deferredStart(in queue: Queueable = Queue.main) -> Self {
        queue.async { [self] in
            start()
        }
        return self
    }

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
