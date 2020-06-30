import Foundation
import NCallback

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

extension Callback {
    convenience init<R: Requestable>(request: R) where ResultType == Result<R.ResponseType, Swift.Error> {
        let start: ServiceClosure = { _ in
            request.start()
        }

        let stop: ServiceClosure = { _ in
            request.stop()
        }

        self.init(start: start,
                  stop: stop,
                  original: request)

        request.onComplete { [weak self] result in
            self?.complete(result)
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
