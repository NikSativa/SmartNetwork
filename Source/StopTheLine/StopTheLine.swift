import Foundation

public protocol StopTheLine {
    func action(with manager: RequestManagering,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: UserInfo,
                completion: @escaping (StopTheLineResult) -> Void)

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
