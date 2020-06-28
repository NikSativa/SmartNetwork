import Foundation

public enum CallbackRetainCycle {
    case selfRetained
    case weakness
}

public typealias ResultCallback<Response, Error: Swift.Error> = Callback<Result<Response, Error>>

public class Callback<ResultType> {
    public typealias Completion = (_ result: ResultType) -> Void

    private var start: () -> Void
    private var stop: () -> Void
    private var beforeCallback: Completion?
    private var completeCallback: Completion?
    private var deferredCallback: Completion?
    private let original: Any?
    private var strongyfy: Callback?

    public required init(start: @escaping () -> Void = { },
                         stop: @escaping () -> Void = { },
                         beforeCallback: Completion? = nil,
                         completeCallback: Completion? = nil,
                         deferredCallback: Completion? = nil,
                         original: Any? = nil) {
        self.start = start
        self.stop = stop
        self.beforeCallback = beforeCallback
        self.completeCallback = completeCallback
        self.deferredCallback = deferredCallback
        self.original = original
    }

    private init<T>(_ original: Callback<T>) {
        self.original = original
        start = original.start
        stop = original.stop
    }

    private init(result: @escaping () -> ResultType) {
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
    public func complete(_ result: ResultType) {
        beforeCallback?(result)
        completeCallback?(result)
        deferredCallback?(result)
        strongyfy = nil
    }

    public func cancel() {
        stop()
        completeCallback = nil
        strongyfy = nil
    }

    public func onComplete(kind: CallbackRetainCycle = .selfRetained, _ callback: @escaping Completion) {
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

    // MARK: - mapping
    public func flatMap<NewResponse>(_ mapper: @escaping (ResultType) -> NewResponse) -> Callback<NewResponse> {
        let copy = Callback<NewResponse>(self)
        let originalCallback = completeCallback
        self.completeCallback = { [weak copy] result in
            originalCallback?(result)
            copy?.complete(mapper(result))
        }
        return copy
    }

    // MARK: - defer
    @discardableResult
    public func deferred(_ callback: @escaping Completion) -> Self {
        let originalCallback = deferredCallback
        self.deferredCallback = { result in
            originalCallback?(result)
            callback(result)
        }

        return self
    }

    public func andThen() -> Self {
        let copy = Self()

        _ = deferred { [weak copy] in
            copy?.complete($0)
        }

        return copy
    }

    @discardableResult
    public func beforeComplete(_ callback: @escaping Completion) -> Self {
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

public extension Callback where ResultType == IgnorableResult {
    func complete() {
        complete(IgnorableResult())
    }
}

public extension Callback {
    func map() -> Callback<IgnorableResult> {
        return flatMap(IgnorableResult.init)
    }
}

public func zip<ResponseA, ResponseB>(_ lhs: Callback<ResponseA>,
                                      _ rhs: Callback<ResponseB>,
                                      _ completion: @escaping (ResponseA, ResponseB) -> Void) {
    let task = {
        var a: ResponseA?
        var b: ResponseB?

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

extension Callback {
    convenience init<R: Requestable>(request: R) where ResultType == Result<R.ResponseType, Swift.Error> {
        let start: () -> Void = {
            request.start()
        }

        let stop: () -> Void = {
            request.stop()
        }

        self.init(start: start,
                  stop: stop,
                  original: request)

        request.onComplete { [weak self] result in
            self?.complete(result)
        }
    }

    // MARK: - completion
    public func complete<Response, Error: Swift.Error>(_ response: Response) where ResultType == Result<Response, Error> {
        complete(.success(response))
    }

    public func complete<Response, Error: Swift.Error>(_ error: Error) where ResultType == Result<Response, Error> {
        complete(.failure(error))
    }

    public func onSuccess<Response, Error: Swift.Error>(kind: CallbackRetainCycle = .selfRetained,
                                                        _ callback: @escaping (_ result: Response) -> Void) where ResultType == Result<Response, Error> {
        onComplete(kind: kind) {
            switch $0 {
            case .success(let value):
                callback(value)
            case .failure:
                break
            }
        }
    }

    // MARK: - mapping
    public func map<NewResponse, Response, Error: Swift.Error>(_ mapper: @escaping (Response) -> NewResponse) -> ResultCallback<NewResponse, Error>
        where ResultType == Result<Response, Error> {
            let copy = ResultCallback<NewResponse, Error>(self)
            let originalCallback = completeCallback
            self.completeCallback = { [weak copy] result in
                originalCallback?(result)
                copy?.complete(result.map(mapper))
            }
            return copy
    }

    public func mapError<Response, Error: Swift.Error, NewError: Swift.Error>(_ mapper: @escaping (Error) -> NewError) -> ResultCallback<Response, NewError>
        where ResultType == Result<Response, Error> {
            let copy = ResultCallback<Response, NewError>(self)
            let originalCallback = completeCallback
            self.completeCallback = { [weak copy] result in
                originalCallback?(result)
                copy?.complete(result.mapError(mapper))
            }
            return copy
    }
}

extension Callback {
    public static func success<Response, Error>(_ result: @escaping @autoclosure () -> Response) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback { () -> Result<Response, Error> in
                return .success(result())
            }
    }

    public static func failure<Response, Error>(_ result: @escaping @autoclosure () -> Error) -> ResultCallback<Response, Error>
        where ResultType == Result<Response, Error> {
            return Callback { () -> Result<Response, Error> in
                return .failure(result())
            }
    }
}

public extension Callback {
    func completeSuccessfully<Error: Swift.Error>() where ResultType == Result<IgnorableResult, Error> {
        complete(.success(IgnorableResult()))
    }
}

public extension Callback {
    func mapSuccess<T, Error: Swift.Error>() -> ResultCallback<IgnorableResult, Error> where ResultType == Result<T, Error> {
        return map(IgnorableResult.init)
    }
}

public func zip<ResponseA, ResponseB, Error: Swift.Error>(_ lhs: ResultCallback<ResponseA, Error>,
                                                          _ rhs: ResultCallback<ResponseB, Error>,
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
