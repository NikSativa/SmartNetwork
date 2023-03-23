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

// public extension StopTheLine {
//    func toAny() -> AnyStopTheLine<Error> {
//        if let self = self as? AnyStopTheLine<Error> {
//            return self
//        }
//
//        return AnyStopTheLine(self)
//    }
// }
//
// public struct AnyStopTheLine<Error: AnyError>: StopTheLine {
//    private let _action: (_ manager: AnyRequestManager<Error>,
//                          _ originalParameters: Parameters,
//                          _ data: ResponseData,
//                          _ userInfo: inout Parameters.UserInfo) -> Callback<StopTheLineResult>
//    private let _verify: (_ data: ResponseData,
//                          _ parameters: Parameters,
//                          _ userInfo: inout Parameters.UserInfo) -> StopTheLineAction
//
//    public init<K: StopTheLine>(_ provider: K) where K.Error == Error {
//        self._action = provider.action(with:originalParameters:response:userInfo:)
//        self._verify = provider.verify(response:for:userInfo:)
//    }
//
//    public func action(with manager: AnyRequestManager<Error>,
//                       originalParameters parameters: Parameters,
//                       response: ResponseData,
//                       userInfo: inout Parameters.UserInfo) -> Callback<StopTheLineResult> {
//        return _action(manager, parameters, response, &userInfo)
//    }
//
//    public func verify(response: ResponseData,
//                       for parameters: Parameters,
//                       userInfo: inout Parameters.UserInfo) -> StopTheLineAction {
//        return _verify(response, parameters, &userInfo)
//    }
// }
