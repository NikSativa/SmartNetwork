import Foundation
import NSpry
import NCallback
import NQueue

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
        return Queue.main.sync {
            return spryify()
        }
    }

    public var isRunning: Bool {
        return Queue.main.sync {
            return spryify()
        }
    }

    public func resume() {
        return Queue.main.sync {
            return spryify()
        }
    }

    public func cancel() {
        return Queue.main.sync {
            return spryify()
        }
    }

    public func observe(_ progressHandler: @escaping ProgressHandler) -> AnyObject {
        return Queue.main.sync {
            return spryify(arguments: progressHandler)
        }
    }
}
