import Foundation
import SmartNetwork
import SpryKit

public final class FakePlugin: Plugin, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case prepare = "prepare(_:request:session:)"
        case verify = "verify(data:userInfo:)"
        case didFinish = "didFinish(withData:userInfo:)"
        case willSend = "willSend(_:request:userInfo:session:)"
        case didReceive = "didReceive(_:request:data:userInfo:)"
        case wasCancelled = "wasCancelled(_:request:userInfo:session:)"
    }

    public let id: AnyHashable
    public let priority: PluginPriority

    public init(id: AnyHashable, priority: PluginPriority) {
        self.id = id
        self.priority = priority
    }

    public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, session: SmartURLSession) {
        return spryify(arguments: parameters, request, session)
    }

    public func verify(data: RequestResult, userInfo: UserInfo) throws {
        return spryify(arguments: data, userInfo)
    }

    public func didFinish(withData data: RequestResult, userInfo: UserInfo) {
        return spryify(arguments: data, userInfo)
    }

    public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo, session: SmartURLSession) {
        return spryify(arguments: parameters, request, userInfo, session)
    }

    public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {
        return spryify(arguments: parameters, request, data, userInfo)
    }

    public func wasCancelled(_ parameters: Parameters, request: any URLRequestRepresentation, userInfo: UserInfo, session: SmartURLSession) {
        return spryify(arguments: parameters, request, userInfo, session, fallbackValue: ())
    }
}

#if swift(>=6.0)
extension FakePlugin: @unchecked Sendable {}
#endif
