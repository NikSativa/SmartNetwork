import Foundation
import NCallback

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

// sourcery: fakable
public protocol StopTheLine {
    associatedtype Error: AnyError

    func action(with manager: AnyRequestManager<Error>,
                originalParameters parameters: Parameters,
                response: ResponseData) -> Callback<StopTheLineResult>

    func verify(response: ResponseData,
                for parameters: Parameters) -> StopTheLineAction
}

public extension StopTheLine {
    func toAny() -> AnyStopTheLine<Error> {
        if let self = self as? AnyStopTheLine<Error> {
            return self
        }

        return AnyStopTheLine(self)
    }
}

public struct AnyStopTheLine<Error: AnyError>: StopTheLine {
    private let _action: (_ manager: AnyRequestManager<Error>,
                          _ originalParameters: Parameters,
                          _ data: ResponseData) -> Callback<StopTheLineResult>
    private let _verify: (_ data: ResponseData,
                          _ parameters: Parameters) -> StopTheLineAction

    public init<K: StopTheLine>(_ provider: K) where K.Error == Error {
        self._action = provider.action(with:originalParameters:response:)
        self._verify = provider.verify(response:for:)
    }

    public func action(with manager: AnyRequestManager<Error>,
                       originalParameters parameters: Parameters,
                       response: ResponseData) -> Callback<StopTheLineResult> {
        return _action(manager, parameters, response)
    }

    public func verify(response: ResponseData,
                       for parameters: Parameters) -> StopTheLineAction {
        return _verify(response, parameters)
    }
}
