import Foundation
import Spry

@testable import NRequest

final
class FakeRequest<ResponseType>: Requestable, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case onComplete = "onComplete()"
        case start = "start()"
        case stop = "stop()"
    }

    func onComplete(_ callback: @escaping CompleteCallback) {
        return spryify(arguments: callback)
    }

    func start() {
        return spryify()
    }

    func stop() {
        return spryify()
    }
}
