import Foundation

/// A protocol defining behavior for stopping the line in ``SmartRequestManager`` based on responses.
///
/// See detailed scheme of network request management with plugins:
/// ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
///
/// - Note: Implement this protocol to define actions for stopping or continuing the execution flow based on request results.
public protocol StopTheLine: SmartSendable {
    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                address: Address,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult

    func verify(response: SmartResponse,
                address: Address,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
