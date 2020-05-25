import Foundation
import Spry

import NRequest

final
class FakePlugin: Plugin, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case prepare = "prepare"
        case willSend = "willSend"
        case didComplete = "didComplete(:responseerror:)"
        case didStop = "didStop"
        case verify = "verify(httpStatusCode:header:data:error:)"
    }

    func prepare(_ info: Info) -> URLRequest {
        return spryify(arguments: info)
    }

    func willSend(_ info: Info) {
        return spryify(arguments: info)
    }

    func didComplete(_ info: Info, response: Any?, error: Error?) {
        return spryify(arguments: info)
    }

    /// including 'cancel'
    func didStop(_ info: Info) {
        return spryify(arguments: info)
    }

    func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
        return spryify(arguments: code, header, data, error)
    }
}
