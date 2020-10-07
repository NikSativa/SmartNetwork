import Foundation
import Spry

@testable import NRequest

public final
class FakeResponseQueue: ResponseQueue, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case async = "async(_:)"
    }

    public init() {
    }

    var workItem: (() -> Void)?
    public func async(_ workItem: @escaping () -> Void) {
        self.workItem = workItem
        return spryify(arguments: workItem)
    }
}
