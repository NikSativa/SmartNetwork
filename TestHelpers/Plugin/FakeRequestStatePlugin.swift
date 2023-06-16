import Foundation
import NRequest
import NSpry

public final class FakeRequestStatePlugin: RequestStatePlugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case willSend = "willSend(_:request:userInfo:)"
        case didReceive = "didReceive(_:request:data:userInfo:)"
    }

    public init() {}

    public func willSend(_ parameters: Parameters,
                         request: URLRequestRepresentation,
                         userInfo: UserInfo) {
        return spryify(arguments: parameters, request, userInfo)
    }

    public func didReceive(_ parameters: Parameters,
                           request: URLRequestRepresentation,
                           data: RequestResult,
                           userInfo: UserInfo) {
        return spryify(arguments: parameters, request, data, userInfo)
    }
}
