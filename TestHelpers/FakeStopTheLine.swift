import Foundation
import NCallback
import NSpry

@testable import NRequest

public final class FakeStopTheLine<Error: AnyError>: StopTheLine, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case action = "action(with:originalParameters:response:)"
        case verify = "verify(response:for:)"
    }

    public func action(with factory: AnyRequestManager<Error>,
                       originalParameters parameters: Parameters,
                       response: ResponseData) -> Callback<StopTheLineResult> {
        return spryify(arguments: factory, parameters, response)
    }

    public func verify(response: ResponseData,
                       for parameters: Parameters) -> StopTheLineAction {
        return spryify(arguments: response, parameters)
    }
}
