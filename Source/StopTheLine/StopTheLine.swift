import Foundation

#if swift(>=6.0)
public protocol StopTheLine: Sendable {
    typealias StopTheLineCompletion = @Sendable (StopTheLineResult) -> Void

    func action(with manager: RequestManagering,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: UserInfo,
                completion: @escaping StopTheLineCompletion)

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
#else
public protocol StopTheLine {
    typealias StopTheLineCompletion = (StopTheLineResult) -> Void

    func action(with manager: RequestManagering,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: UserInfo,
                completion: @escaping StopTheLineCompletion)

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
#endif
