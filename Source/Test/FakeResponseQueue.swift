import Foundation
import Spry

@testable import NRequest

final
class FakeResponseQueue: ResponseQueue, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case async = "async(_:)"
    }

    var workItem: (() -> Void)?
    func async(_ workItem: @escaping () -> Void) {
        self.workItem = workItem
        return spryify(arguments: workItem)
    }
}
