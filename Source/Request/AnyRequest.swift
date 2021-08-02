import Foundation
import UIKit

struct AnyRequest<Response: CustomDecodable, Error: AnyError>: Request {
    private let _prepare: () -> RequestInfo
    private let _start: () -> Void
    private let _stop: () -> Void
    private let _onComplete: (_ callback: @escaping CompletionCallback) -> Void

    init<R: Request>(_ base: R) where R.Error == Error, R.Response == Response {
        self._prepare = base.prepare
        self._start = base.start
        self._stop = base.stop
        self._onComplete = base.onComplete
    }

    @discardableResult
    func prepare() -> RequestInfo {
        return _prepare()
    }

    func start() {
        _start()
    }
    func stop() {
        _stop()
    }

    typealias CompletionCallback = (Result<Response.Object, Error>) -> Void
    func onComplete(_ callback: @escaping CompletionCallback) {
        _onComplete(callback)
    }
}
