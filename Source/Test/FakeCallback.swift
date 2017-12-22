import Foundation
import Spry

@testable import NRequest

class FakeCallback<Response, Error: Swift.Error>: Callback<Response, Error>, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case onComplete = "onComplete()"
        case complete = "complete(_:)"
        case cancel = "cancel()"
    }

    var callback: CompleteCallback?
    override func onComplete(_ callback: @escaping CompleteCallback) {
        self.callback = callback
        return spryify(arguments: callback)
    }

    override func complete(_ result: Result<Response, Error>) {
        return spryify(arguments: result)
    }

    override func cancel() {
        return spryify()
    }
}
