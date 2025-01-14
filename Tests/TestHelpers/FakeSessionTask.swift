import Foundation
import SmartNetwork
import SpryKit
import Threading

public final class FakeSessionTask: SessionTask, Spryable, SpryEquatable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case progress
        case isRunning
        case resume = "resume()"
        case cancel = "cancel()"
        case observe = "observe(_:)"
    }

    public var progress: Progress {
        return spryify()
    }

    public var isRunning: Bool {
        return spryify()
    }

    public func resume() {
        return spryify()
    }

    public func cancel() {
        return spryify()
    }

    public var progressHandler: ProgressHandler?
    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        self.progressHandler = progressHandler
        return spryify(arguments: progressHandler)
    }
}
