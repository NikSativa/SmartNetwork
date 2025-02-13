import Foundation
import SmartNetwork
import SpryKit
import Threading

public final class FakeSmartURLSession: SmartURLSession, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case configuration
        case task = "task(for:)"
    }

    public init() {}

    public var configuration: URLSessionConfiguration {
        return spryify()
    }

    public func task(for request: URLRequest) async throws -> (URLSession.AsyncBytes, URLResponse) {
        return spryify(arguments: request)
    }
}

#if swift(>=6.0)
extension FakeSmartURLSession: @unchecked Sendable {}
#endif
