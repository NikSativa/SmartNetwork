import Foundation
import Spry

@testable import NRequest

final
class FakeRequest<Response: CustomDecodable, Error: AnyError>: Request, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case onComplete = "onComplete()"
        case start = "start()"
        case stop = "stop()"
    }

    func onComplete(_ callback: @escaping CompletionCallback) {
        return spryify(arguments: callback)
    }

    func start() {
        return spryify()
    }

    func stop() {
        return spryify()
    }
}
