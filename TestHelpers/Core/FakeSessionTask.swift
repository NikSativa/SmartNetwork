import Foundation
import NQueue
import NSpry

@testable import NRequest

public final class FakeSessionTask: SessionTask, Spryable, SpryEquatable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case progressContainer
        case isRunning
        case resume = "resume()"
        case cancel = "cancel()"
        case observe = "observe(_:)"
    }

    public var progressContainer: NRequest.Progress {
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

    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return spryify(arguments: progressHandler)
    }
}
