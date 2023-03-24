import Foundation
import NQueue
import NSpry

@testable import NRequest

public final class FakeSession: Session, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case task = "task(with:completionHandler:)"
    }

    public init() {}

    var completionHandler: CompletionHandler?
    public func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask {
        self.completionHandler = completionHandler
        return spryify(arguments: request, completionHandler)
    }
}
