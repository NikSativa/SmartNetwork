import Foundation
import NSpry

@testable import NRequest

public final class FakeRequest: Request, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case parameters
        case restartIfNeeded = "restartIfNeeded()"
        case start = "start(with:)"
        case cancel = "cancel()"
    }

    public init() {
    }

    public var parameters: Parameters {
        return spryify()
    }

    public func restartIfNeeded() {
        return spryify()
    }

    public func cancel() {
        return spryify()
    }

    public func start(with completion: @escaping CompletionCallback) {
        return spryify(arguments: completion)
    }
}
