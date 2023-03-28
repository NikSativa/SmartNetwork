import Foundation
import NSpry

@testable import NRequest

public final class FakeRequestable: Requestable, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case completion
        case parameters
        case urlRequestable
        case userInfo
        case restartIfNeeded = "restartIfNeeded()"
        case start = "start()"
        case cancel = "cancel()"
    }

    public init() {}

    public var urlRequestable: URLRequestRepresentation {
        get {
            return stubbedValue()
        }
        set {
            return recordCall(arguments: newValue)
        }
    }

    public var userInfo: Parameters.UserInfo {
        get {
            return stubbedValue()
        }
        set {
            return recordCall(arguments: newValue)
        }
    }

    public var completion: CompletionCallback? {
        get {
            return stubbedValue()
        }
        set {
            return recordCall(arguments: newValue)
        }
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

    public func start() {
        return spryify()
    }
}
