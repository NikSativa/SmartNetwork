import Foundation
import NCallback

extension Callback {
    convenience init<Requestable: Request>(request: Requestable)
    where ResultType == Result<Requestable.Response.Object, Requestable.Error> {
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
