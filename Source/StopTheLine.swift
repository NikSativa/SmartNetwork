import Foundation
import NCallback

public enum StopTheLineAction: Equatable {
    case stopTheLine
    case passOver
    case retry
}

public protocol StopTheLine {
    associatedtype Error: AnyError
    func makeRequest(_ factory: AnyRequestFactory<Error>,
                     request: MutableRequest,
                     error: Error) -> Callback<Ignorable>
    func action(for error: Error,
                with info: RequestInfo) -> StopTheLineAction
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
    private let _makeRequest: (_ factory: AnyRequestFactory<Error>, _ request: MutableRequest, _ error: Error) -> Callback<Ignorable>
    private let _action: (_ error: Error, _ info: RequestInfo) -> StopTheLineAction

    public init<K: StopTheLine>(_ provider: K) where K.Error == Error {
        self._makeRequest = provider.makeRequest(_:request:error:)
        self._action = provider.action(for:with:)
    }

    public func makeRequest(_ factory: AnyRequestFactory<Error>,
                            request: MutableRequest,
                            error: Error) -> Callback<Ignorable> {
        return _makeRequest(factory, request, error)
    }

    public func action(for error: Error,
                       with info: RequestInfo) -> StopTheLineAction {
        return _action(error, info)
    }
}
