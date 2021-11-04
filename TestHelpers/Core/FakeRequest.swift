import Foundation
import NSpry

@testable import NRequest

final class FakeRequest: Request, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case parameters
        case restartIfNeeded = "restartIfNeeded()"
        case start = "start(with:)"
        case cancel = "cancel()"
    }

    var parameters: Parameters {
        return spryify()
    }

    func restartIfNeeded() {
        return spryify()
    }

    func cancel() {
        return spryify()
    }

    func start(with completion: @escaping CompletionCallback) {
        return spryify(arguments: completion)
    }
}
