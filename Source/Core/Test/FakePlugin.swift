import Foundation
import Spry

import NRequest

public final
class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare"
        case willSend = "willSend"
        case didComplete = "didComplete(:responseerror:)"
        case didStop = "didStop"
        case verify = "verify(httpStatusCode:header:data:error:)"
    }

    public init() {
    }

    public func prepare(_ info: Info) -> URLRequest {
        return spryify(arguments: info)
    }

    public func willSend(_ info: Info) {
        return spryify(arguments: info)
    }

    public func didComplete(_ info: Info, response: Any?, error: Error?) {
        return spryify(arguments: info)
    }

    /// including 'cancel'
    public func didStop(_ info: Info) {
        return spryify(arguments: info)
    }

    public func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
        return spryify(arguments: code, header, data, error)
    }
}
