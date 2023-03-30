import Foundation
import NRequest
import NSpry

public final class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:request:)"
        case verify = "verify(data:userInfo:)"
    }

    public init() {}

    public func prepare(_ parameters: Parameters,
                        request: inout URLRequestRepresentation) {
        return spryify(arguments: parameters, request)
    }

    public func verify(data: RequestResult,
                       userInfo: UserInfo) throws {
        return spryify(arguments: data)
    }
}
