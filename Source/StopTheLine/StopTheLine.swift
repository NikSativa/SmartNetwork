import Foundation

public protocol StopTheLine {
    func action(with manager: some RequestManager,
                originalParameters parameters: Parameters,
                response: RequestResult,
                userInfo: inout Parameters.UserInfo) async -> StopTheLineResult

    func verify(response: RequestResult,
                for parameters: Parameters,
                userInfo: inout Parameters.UserInfo) -> StopTheLineAction
}
