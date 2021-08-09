import Foundation
import UIKit

internal extension Request {
    func toAny() -> AnyRequest<Response, Error> {
        if let self = self as? AnyRequest<Response, Error> {
            return self
        }

        return AnyRequest(self)
    }
}

internal final class AnyRequest<Response: CustomDecodable, Error: AnyError>: Request {
    private let _setParameters: (Parameters) throws -> Void
    private let _info: () -> RequestInfo
    private let _isSpecial: () -> Bool
    private let _start: () -> Void
    private let _stop: () -> Void
    private let _onComplete: (_ callback: @escaping CompletionCallback) -> Void
    private let _onSpecialComplete: (_ callback: @escaping SpecialCompletionCallback) -> Void
    private let _cancelSpecialCompletion: () -> Void

    init<R: Request>(_ base: R) where R.Error == Error, R.Response == Response {
        self._setParameters = base.set(_:)
        self._info = { base.info }
        self._isSpecial = { base.isSpecial }
        self._start = base.start
        self._stop = base.stop
        self._onComplete = base.onComplete(_:)
        self._onSpecialComplete = base.onSpecialComplete(_:)
        self._cancelSpecialCompletion = base.cancelSpecialCompletion
    }

    public func stop() {
        _stop()
    }

    typealias CompletionCallback = (Result<Response.Object, Error>) -> Void
    public func onComplete(_ callback: @escaping CompletionCallback) {
        _onComplete(callback)
    }

    public var isSpecial: Bool {
        return _isSpecial()
    }

    public func start() {
        _start()
    }

    public var info: RequestInfo {
        return _info()
    }

    public func set(_ parameters: Parameters) throws {
        try _setParameters(parameters)
    }

    public func onSpecialComplete(_ callback: @escaping SpecialCompletionCallback) {
        _onSpecialComplete(callback)
    }

    public func cancelSpecialCompletion() {
        _cancelSpecialCompletion()
    }
}
