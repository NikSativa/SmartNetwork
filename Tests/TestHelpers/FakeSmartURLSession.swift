import Foundation
import SpryKit
import Threading

@testable import SmartNetwork

public final class FakeSmartURLSession: SmartURLSession, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case configuration
        case task = "task(with:completionHandler:)"
    }

    public init() {}

    public var configuration: URLSessionConfiguration {
        return spryify()
    }

    var completionHandler: CompletionHandler?
    public func task(with request: URLRequest, completionHandler: @escaping CompletionHandler) -> SessionTask {
        self.completionHandler = completionHandler
        return spryify(arguments: request, completionHandler)
    }
}

#if swift(>=6.0)
extension FakeSmartURLSession: @unchecked Sendable {}
#endif
