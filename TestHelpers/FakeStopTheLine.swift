import Foundation
import SpryKit
import Threading

@testable import SmartNetwork

public final class FakeStopTheLine: StopTheLine, Spryable, SpryEquatable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case action = "action(with:originalParameters:response:userInfo:completion:)"
        case verify = "verify(response:for:userInfo:)"
    }

    var completion: ((StopTheLineResult) -> Void)?
    public func action(with manager: RequestManagering,
                       originalParameters parameters: Parameters,
                       response: RequestResult,
                       userInfo: UserInfo,
                       completion: @escaping (StopTheLineResult) -> Void) {
        self.completion = completion
        return spryify(arguments: manager, parameters, response, userInfo, completion)
    }

    public func verify(response: RequestResult,
                       for parameters: Parameters,
                       userInfo: UserInfo) -> StopTheLineAction {
        return spryify(arguments: response, parameters, userInfo)
    }
}
