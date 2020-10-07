import Foundation
import Spry

@testable import NRequest

final
class FakeRequest<Response: InternalDecodable, Error: AnyError>: Request<Response, Error>, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case onComplete = "onComplete()"
        case start = "start()"
        case stop = "stop()"
    }

    override func onComplete(_ callback: @escaping CompleteCallback) {
        return spryify(arguments: callback)
    }

    override func start() {
        return spryify()
    }

    override func stop() {
        return spryify()
    }
}
