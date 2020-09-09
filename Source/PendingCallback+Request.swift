import Foundation
import NCallback

public extension PendingCallback where ResultType == IgnorableResult {
    func complete() {
        complete(IgnorableResult())
    }
}

public extension PendingCallback {
    func completeSuccessfully<Error: Swift.Error>() where ResultType == Result<IgnorableResult, Error> {
        complete(.success(IgnorableResult()))
    }

    func complete<Response, Error: Swift.Error>(_ error: Error) where ResultType == Result<Response, Error> {
        complete(.failure(error))
    }

    func complete<Response, Error: Swift.Error>(_ result: Response) where ResultType == Result<Response, Error> {
        complete(.success(result))
    }
}
