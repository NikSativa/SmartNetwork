import Foundation
import Spry

@testable import NRequest

final
class FakeRequest<Response: CustomDecodable, Error: AnyError>: Request, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case prepareRequestInfo = "prepareRequestInfo()"
        case onComplete = "onComplete()"
        case start = "start()"
        case startWithInfo = "start(with:)"
        case stop = "stop()"
    }

    func prepareRequestInfo() -> RequestInfo {
        return spryify()
    }

    func onComplete(_ callback: @escaping CompletionCallback) {
        return spryify(arguments: callback)
    }

    func start() {
        return spryify()
    }

    func start(with info: RequestInfo) {
        return spryify(arguments: info)
    }

    func stop() {
        return spryify()
    }
}
