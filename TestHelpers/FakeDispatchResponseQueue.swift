import Foundation
import Spry

@testable import NRequest

public final
class FakeDispatchResponseQueue: DispatchResponseQueue, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case async = "async(_:)"
        case sync = "sync(_:)"
    }

    public init() {
    }

    var asyncWorkItem: (() -> Void)?
    public func async(_ workItem: @escaping () -> Void) {
        self.asyncWorkItem = workItem
        return spryify(arguments: workItem)
    }

    var syncWorkItem: (() -> Void)?
    public func sync(_ workItem: @escaping () -> Void) {
        self.syncWorkItem = workItem
        return spryify(arguments: workItem)
    }
}
