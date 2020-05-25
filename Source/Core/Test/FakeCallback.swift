import Foundation
import Spry

@testable import NRequest

final
class FakeCallback<Response, Error: Swift.Error>: Callback<Response, Error>, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case onComplete = "onComplete(kind:_:)"
        case complete = "complete(kind:_:)"
        case cancel = "cancel()"

        case flatMap = "flatMap(_:)"
        case map = "map(_:)"
        case mapError = "mapError(_:)"
    }

    var onCompleteCallback: CompleteCallback?
    override public func onComplete(kind: CallbackRetainCycle = .selfRetained, _ callback: @escaping CompleteCallback) {
        self.onCompleteCallback = callback
        return spryify(arguments: kind, callback)
    }

    override func complete(_ result: Result<Response, Error>) {
        return spryify(arguments: result)
    }

    override func cancel() {
        return spryify()
    }

    override func flatMap<NewResponse, NewError>(_ mapper: @escaping (Result<Response, Error>) -> Result<NewResponse, NewError>) -> Callback<NewResponse, NewError> where NewError: Swift.Error {
        return spryify(arguments: mapper)
    }

    override public func map<NewResponse>(_ mapper: @escaping (Response) -> NewResponse) -> Callback<NewResponse, Error> {
        return spryify(arguments: mapper)
    }

    override func mapError<NewError>(_ mapper: @escaping (Error) -> NewError) -> Callback<Response, NewError> where NewError: Swift.Error {
        return spryify(arguments: mapper)
    }
}
