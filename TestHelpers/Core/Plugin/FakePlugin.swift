import Foundation
import NRequest
import NSpry

public final class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:request:userInfo:)"
        case willSend = "willSend(_:request:)"
        case didReceive = "didReceive(_:data:)"
        case didFinish = "didFinish(_:data:dto:)"
        case verify = "verify(data:)"
    }

    public init() {}

    public func prepare(_ parameters: Parameters,
                        request: inout URLRequestable,
                        userInfo: inout Parameters.UserInfo) {
        return spryify(arguments: parameters, userInfo, request)
    }

    public func willSend(_ parameters: Parameters,
                         request: URLRequestable,
                         userInfo: inout Parameters.UserInfo) {
        return spryify(arguments: parameters, request)
    }

    public func didReceive(_ parameters: Parameters,
                           data: ResponseData,
                           userInfo: inout Parameters.UserInfo) {
        return spryify(arguments: parameters, data)
    }

    public func didFinish(_ parameters: Parameters,
                          data: ResponseData,
                          userInfo: inout Parameters.UserInfo,
                          dto: Any?) {
        return spryify(arguments: parameters, data, dto)
    }

    public func verify(data: ResponseData,
                       userInfo: inout Parameters.UserInfo) throws {
        return spryify(arguments: data)
    }
}
