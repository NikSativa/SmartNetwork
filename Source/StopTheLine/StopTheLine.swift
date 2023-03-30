import Foundation

public protocol StopTheLine {
    func action(with manager: some RequestManager,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: UserInfo) async -> StopTheLineResult

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction
}
