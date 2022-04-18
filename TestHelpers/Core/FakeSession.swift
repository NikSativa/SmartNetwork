import Foundation
import NQueue
import NSpry

@testable import NRequest

public final class FakeSession: Session, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case copy = "copy(with:)"
        case task = "task(with:completionHandler:)"
        case finishTasksAndInvalidate = "finishTasksAndInvalidate()"
    }

    public init() {}

    public func copy(with delegate: SessionDelegate) -> Session {
        return spryify(arguments: delegate)
    }

    public func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask {
        return spryify(arguments: request, completionHandler)
    }

    public func finishTasksAndInvalidate() {
        return spryify()
    }
}
