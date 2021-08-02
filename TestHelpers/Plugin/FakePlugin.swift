import Foundation
import NSpry

import NRequest

public final class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:)"
        case willSend = "willSend(_:)"
        case verify = "verify(httpStatusCode:header:data:error:)"
        case didFinish = "didFinish(_:response:with:responseBody:statusCode:)"
    }

    public init() {
    }

    public func prepare(_ info: inout Info) {
        return spryify(arguments: info)
    }

    public func willSend(_ info: Info) {
        return spryify(arguments: info)
    }

    public func verify(httpStatusCode code: Int?, header: [AnyHashable: Any], data: Data?, error: Error?) throws {
        return spryify(arguments: code, header, data, error)
    }

    public func didFinish(_ info: Info, response: URLResponse?, with error: Error?, responseBody body: Data?, statusCode code: Int?) {
        return spryify(arguments: info, response, error, body, code)
    }
}
