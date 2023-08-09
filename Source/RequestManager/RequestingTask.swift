import Combine
import Foundation
import NQueue

public final class RequestingTask {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var cancelAction: (() -> Void)?

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var runAction: (() -> Void)?

    public init(runAction: @escaping () -> Void,
                cancelAction: (() -> Void)? = nil) {
        self.runAction = runAction
        self.cancelAction = cancelAction
    }

    @discardableResult
    public func start() -> Self {
        precondition(runAction != nil, "should be called only once")
        let runAction = runAction
        self.runAction = nil
        runAction?()
        return self
    }

    @discardableResult
    public func deferredStart(in queue: Queueable = Queue.main) -> Self {
        queue.async {
            self.start()
        }
        return self
    }

    public func cancel() {
        runAction = nil

        let cancelAction = cancelAction
        self.cancelAction = nil
        cancelAction?()
    }

    deinit {
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
}
