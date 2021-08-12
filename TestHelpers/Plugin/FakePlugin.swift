import Foundation
import NSpry

import NRequest

public final class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:request:)"
        case willSend = "willSend(_:request:)"
        case didFinish = "didFinish(_:response:request:data:)"
        case verify = "verify(data:)"
    }

    public init() {
    }


    public func prepare(_ parameters: Parameters, request: inout URLRequestable) {
        return spryify(arguments: parameters, request)
    }

    public func willSend(_ parameters: Parameters, request: URLRequestable) {
        return spryify(arguments: parameters, request)
    }

    public func didFinish(_ parameters: Parameters, request: URLRequestable, data: ResponseData) {
        return spryify(arguments: parameters, request, data)
    }

    public func verify(data: ResponseData) throws {
        return spryify(arguments: data)
    }
}
