import Foundation

public enum CallbackRetainCycle {
    case selfRetained
    case weakness
}

public class Callback<Response, Error: Swift.Error> {
    public typealias CompleteCallback = (_ result: Result<Response, Error>) -> Void

    private var start: () -> Void
    private var stop: () -> Void
    private var beforeCallback: CompleteCallback?
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

    // MARK: - completion
    public func complete(_ result: Result<Response, Error>) {
        beforeCallback?(result)
        completeCallback?(result)
        deferredCallback?(result)
        strongyfy = nil
    }

    public func complete(_ response: Response) {
        complete(.success(response))
    }

    public func complete(_ error: Error) {
        complete(.failure(error))
    }

    public func cancel() {
        stop()
        completeCallback = nil
        strongyfy = nil
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

    public func oneWay(kind: CallbackRetainCycle = .selfRetained) {
        onComplete(kind: kind, { _ in })
    }

    public func onSuccess(kind: CallbackRetainCycle = .selfRetained, _ callback: @escaping (_ result: Response) -> Void) {
        onComplete {
            switch $0 {
            case .success(let value):
                callback(value)
            case .failure:
                break
            }
        }
    }

    // MARK: - mapping
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

    // MARK: - defer
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

    @discardableResult
    public func beforeComplete(_ callback: @escaping CompleteCallback) -> Callback {
        let originalCallback = beforeCallback
        self.beforeCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
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

public extension Callback where Response == IgnorableResult {
    func completeSuccessfully() {
        complete(.success(IgnorableResult()))
    }
}

public extension Callback {
    func mapSuccess() -> Callback<IgnorableResult, Error> {
        return map(IgnorableResult.init)
    }
}

public func zip<ResponseA, ErrorA: Swift.Error, ResponseB, ErrorB: Swift.Error>(_ lhs: Callback<ResponseA, ErrorA>,
                                                                                _ rhs: Callback<ResponseB, ErrorB>,
                                                                                _ completion: @escaping (Result<ResponseA, ErrorA>, Result<ResponseB, ErrorB>) -> Void) {
    let task = {
        var a: Result<ResponseA, ErrorA>?
        var b: Result<ResponseB, ErrorB>?

        let check = {
            guard let a = a, let b = b else {
                return
            }
            completion(a, b)
        }

        lhs.onComplete { result in
            a = result
            check()
        }

        rhs.onComplete { result in
            b = result
            check()
        }
    }

    task()
}

public func zip<ResponseA, ResponseB, Error: Swift.Error>(_ lhs: Callback<ResponseA, Error>,
                                                          _ rhs: Callback<ResponseB, Error>,
                                                          _ completion: @escaping (Result<(ResponseA, ResponseB), Error>) -> Void) {
    zip(lhs, rhs) {
        switch ($0, $1) {
        case (.success(let a), .success(let b)):
            completion(.success((a, b)))
        case (.failure(let error), _):
            completion(.failure(error))
        case (_, .failure(let error)):
            completion(.failure(error))
        }
    }
}
