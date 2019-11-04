import Foundation

public enum CallbackRetainCycle {
    case selfRetained
    case weakness
}

public class Callback<Response, Error: Swift.Error> {
    public typealias CompleteCallback = (_ result: Result<Response, Error>) -> Void

    private var start: () -> Void
    private var stop: () -> Void
    private var completeCallback: CompleteCallback?
    private var deferredCallback: CompleteCallback?
    private let original: Any?
    private var strongyfy: Callback?

    public init() {
        original = nil
        start = { }
        stop = { }
    }

    init<R: Requestable>(request: R) where R.ResponseType == Response, Error == Swift.Error {
        original = request

        start = {
            request.start()
        }

        stop = {
            request.stop()
        }

        request.onComplete { [weak self] result in
            self?.complete(result)
        }
    }

    private init<T, E>(_ original: Callback<T, E>) {
        self.original = original
        start = original.start
        stop = original.stop
    }

    private init(result: @escaping () -> Result<Response, Error>) {
        original = nil

        start = { }
        stop = { }

        start = { [weak self] in
            self?.complete(result())
        }
    }

    deinit {
        stop()
    }

    public func complete(_ result: Result<Response, Error>) {
        completeCallback?(result)
        deferredCallback?(result)
        strongyfy = nil
    }

    public func cancel() {
        stop()
    }

    public func onComplete(kind: CallbackRetainCycle = .selfRetained, _ callback: @escaping CompleteCallback) {
        switch kind {
        case .selfRetained:
            strongyfy = self
        case .weakness:
            strongyfy = nil
        }

        assert(completeCallback == nil)
        completeCallback = callback

        start()
    }
}

extension Callback: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public static func == (lhs: Callback, rhs: Callback) -> Bool {
        return lhs === rhs
    }
}

extension Callback {
    public static func success(_ result: @escaping @autoclosure () -> Response) -> Callback<Response, Error> {
        return Callback { () -> Result<Response, Error> in
            return .success(result())
        }
    }

    public static func failure(_ result: @escaping @autoclosure () -> Error) -> Callback<Response, Error> {
        return Callback { () -> Result<Response, Error> in
            return .failure(result())
        }
    }
}

extension Callback {
    public func flatMap<NewResponse, NewError>(_ mapper: @escaping (Result<Response, Error>) -> Result<NewResponse, NewError>) -> Callback<NewResponse, NewError> where NewError: Swift.Error {
        let copy = Callback<NewResponse, NewError>(self)
        let originalCallback = completeCallback
        self.completeCallback = { [weak copy] result in
            originalCallback?(result)
            copy?.complete(mapper(result))
        }
        return copy
    }

    public func map<NewResponse>(_ mapper: @escaping (Response) -> NewResponse) -> Callback<NewResponse, Error> {
        let copy = Callback<NewResponse, Error>(self)
        let originalCallback = completeCallback
        self.completeCallback = { [weak copy] result in
            originalCallback?(result)
            copy?.complete(result.map(mapper))
        }
        return copy
    }

    public func mapError<NewError>(_ mapper: @escaping (Error) -> NewError) -> Callback<Response, NewError> where NewError: Swift.Error {
        let copy = Callback<Response, NewError>(self)
        let originalCallback = completeCallback
        self.completeCallback = { [weak copy] result in
            originalCallback?(result)
            copy?.complete(result.mapError(mapper))
        }
        return copy
    }
}

extension Callback {
    @discardableResult
    public func deferred(_ callback: @escaping CompleteCallback) -> Callback {
        let originalCallback = deferredCallback
        self.deferredCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    public func andThen() -> Callback {
        let copy = Callback()

        _ = deferred { [weak copy] in
            copy?.complete($0)
        }

        return copy
    }
}
