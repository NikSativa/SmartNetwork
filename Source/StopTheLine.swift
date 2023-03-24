import Foundation

public enum StopTheLineAction: Equatable {
    case stopTheLine
    case passOver
    case retry
}

public enum StopTheLineResult {
    /// pass over new response
    case passOver(ResponseData)

    /// use original response
    case useOriginal

    /// ignore current response and retry request
    case retry
}

public protocol StopTheLine {
    func action(with manager: some RequestManager,
                originalParameters parameters: Parameters,
                response: ResponseData,
                userInfo: inout Parameters.UserInfo) async -> StopTheLineResult

    func verify(response: ResponseData,
                for parameters: Parameters,
                userInfo: inout Parameters.UserInfo) -> StopTheLineAction
}
