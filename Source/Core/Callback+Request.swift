import Foundation
import NCallback

extension Callback {
    convenience init<R: InternalDecodable, Error: AnyError>(request: Request<R, Error>) where ResultType == Result<R.Object, Error> {
        let start: ServiceClosure = { _ in
            request.start()
        }

        let stop: ServiceClosure = { _ in
            request.stop()
        }

        self.init(start: start, stop: stop)

        request.onComplete { [weak self] result in
            self?.complete(result)
        }
    }
}
