// import Foundation
// import NSpry
//
// @testable import NRequest
//
// public final class FakeStopTheLine<Error: AnyError>: StopTheLine, Spryable {
//    public enum ClassFunction: String, StringRepresentable {
//        case empty
//    }
//
//    public enum Function: String, StringRepresentable {
//        case action = "action(with:originalParameters:response:userInfo:)"
//        case verify = "verify(response:for:userInfo:)"
//    }
//
//    public func action(with factory: AnyRequestManager<Error>,
//                       originalParameters parameters: Parameters,
//                       response: ResponseData,
//                       userInfo: inout Parameters.UserInfo) -> Callback<StopTheLineResult> {
//        return spryify(arguments: factory, parameters, response, userInfo)
//    }
//
//    public func verify(response: ResponseData,
//                       for parameters: Parameters,
//                       userInfo: inout Parameters.UserInfo) -> StopTheLineAction {
//        return spryify(arguments: response, parameters, userInfo)
//    }
// }
