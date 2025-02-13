#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import SpryKit

@Spryable
final class FakePlugin: Plugin {
    @SpryableVar
    var id: AnyHashable
    @SpryableVar
    var priority: PluginPriority

    public init(id: AnyHashable, priority: PluginPriority) {
        stub(.id).andReturn(id)
        stub(.priority).andReturn(priority)
    }

    @SpryableFunc
    func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async

    @SpryableFunc
    func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession)

    @SpryableFunc
    func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, data: SmartResponse)

    @SpryableFunc
    func verify(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) throws

    @SpryableFunc
    func didFinish(parameters: Parameters, userInfo: UserInfo, data: SmartResponse)

    @SpryableFunc
    func wasCancelled(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession)
}

extension FakePlugin: @unchecked Sendable {}
#endif
