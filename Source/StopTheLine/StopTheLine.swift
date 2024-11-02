import Foundation

#if swift(>=6.0)
/// A protocol defining behavior for stopping the line in ``SmartRequestManager`` based on responses.
///
/// - Note: Implement this protocol to define actions for stopping or continuing the execution flow based on request results.
public protocol StopTheLine: Sendable {
    typealias StopTheLineCompletion = (StopTheLineResult) -> Void

    func action(with manager: SmartRequestManager,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: UserInfo,
                completion: @escaping StopTheLineCompletion)

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
#else
/// A protocol defining behavior for stopping the line in ``SmartRequestManager`` based on responses.
///
/// - Note: Implement this protocol to define actions for stopping or continuing the execution flow based on request results.
public protocol StopTheLine {
    typealias StopTheLineCompletion = (StopTheLineResult) -> Void

    func action(with manager: SmartRequestManager,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: UserInfo,
                completion: @escaping StopTheLineCompletion)

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
#endif
