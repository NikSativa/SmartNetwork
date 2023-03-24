import Foundation
import NQueue

public final class LoadingTask {
    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var cancelAction: (() -> Void)?

    @Atomic(mutex: Mutex.pthread(.recursive), read: .sync, write: .sync)
    private var runAction: (() -> Void)?

    internal init(runAction: @escaping () -> Void,
                  cancelAction: (() -> Void)? = nil) {
        self.runAction = runAction
        self.cancelAction = cancelAction
    }

    public func resume() {
        let runAction = runAction
        self.runAction = nil
        runAction?()
    }

    public func cancel() {
        let cancelAction = cancelAction
        self.cancelAction = nil
        cancelAction?()
    }

    deinit {
        cancelAction?()
    }
}
