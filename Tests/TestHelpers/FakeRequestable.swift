import Foundation
import SpryKit

@testable import SmartNetwork

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
        case restart = "restart()"
        case cancel = "cancel()"
    }

    public init() {}

    public var urlRequestable: URLRequestRepresentation {
        get {
            return spryify()
        }
        set {
            return spryify(arguments: newValue)
        }
    }

    public var userInfo: UserInfo {
        get {
            return spryify()
        }
        set {
            return spryify(arguments: newValue)
        }
    }

    public var completion: CompletionCallback? {
        get {
            return spryify()
        }
        set {
            return spryify(arguments: newValue)
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

    public func restart() {
        return spryify()
    }
}
