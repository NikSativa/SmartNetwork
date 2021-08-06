import Foundation
import NSpry

@testable import NRequest

final class FakeRequest<Response: CustomDecodable, Error: AnyError>: Request, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case prepare = "prepare()"
        case onComplete = "onComplete()"
        case start = "start()"
        case stop = "stop()"
        case isSpecial
        case info
        case setParameters = "set(_:)"
        case onSpecialComplete = "onSpecialComplete(_:)"
        case cancelSpecialCompletion = "cancelSpecialCompletion()"
    }

    func prepare() -> RequestInfo {
        return spryify()
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

    var isSpecial: Bool {
        return spryify()
    }

    var info: RequestInfo {
        return spryify()
    }

    func set(_ parameters: Parameters) throws {
        return spryify(arguments: parameters)
    }

    func onSpecialComplete(_ callback: @escaping SpecialCompletionCallback) {
        return spryify(arguments: callback)
    }

    func cancelSpecialCompletion() {
        return spryify()
    }
}
