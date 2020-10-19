import Foundation
import Spry

import NRequest

public final
class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:)"
        case willSend = "willSend(_:)"
        case didComplete = "didComplete(:responseerror:)"
        case didStop = "didStop(_:)"
        case verify = "verify(httpStatusCode:header:data:error:)"
    }

    public init() {
    }

    public func prepare(_ info: Info) {
        return spryify(arguments: info)
    }

    public func willSend(_ info: Info) {
        return spryify(arguments: info)
    }

    public func didFinish(_ info: Info, response: URLResponse?, with error: Error?, statusCode: Int?) {
        return spryify(arguments: info, response, error, statusCode)
    }

    public func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
        return spryify(arguments: code, header, data, error)
    }
}
