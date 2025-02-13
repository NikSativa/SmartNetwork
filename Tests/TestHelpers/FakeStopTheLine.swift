#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import SpryKit
import Threading

@Spryable
final class FakeStopTheLine: StopTheLine {
    @SpryableFunc
    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                address: Address,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult

    @SpryableFunc
    func verify(response: SmartResponse,
                address: Address,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
#endif
