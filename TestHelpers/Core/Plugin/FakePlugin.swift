import Foundation
import NRequest
import NSpry

public final class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:request:userInfo:)"
        case verify = "verify(data:)"
    }

    public init() {}

    public func prepare(_ parameters: Parameters,
                        request: inout URLRequestWrapper,
                        userInfo: inout Parameters.UserInfo) {
        return spryify(arguments: parameters, userInfo, request)
    }

    public func verify(data: ResponseData,
                       userInfo: Parameters.UserInfo) throws {
        return spryify(arguments: data)
    }
}
