import Foundation
import NCallback

public enum StopTheLineAction: Equatable {
    case stopTheLine
    case passOver
    case retry
}

public protocol StopTheLine {
    associatedtype Error: AnyError
    func makeRequest<R: RequestFactory>(_ factory: R) -> Callback<Ignorable> where R.Error == Error
    func action(for error: Error, with info: RequestInfo) -> StopTheLineAction
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
    private let box: AbstractRefreshToken<Error>

    public init<K: StopTheLine>(_ provider: K) where K.Error == Error {
        self.box = RefreshTokenBox(provider)
    }

    public func makeRequest<R>(_ originalFactory: R) -> Callback<Ignorable> where R: RequestFactory, Error == R.Error {
        return box.makeRequest(originalFactory)
    }

    public func action(for error: Error, with info: RequestInfo) -> StopTheLineAction {
        return box.action(for: error, with: info)
    }
}

private class AbstractRefreshToken<Error: AnyError>: StopTheLine {
    func action(for error: Error, with info: RequestInfo) -> StopTheLineAction {
        fatalError("abstract needs override")
    }

    func makeRequest<R>(_ originalFactory: R) -> Callback<Ignorable> where R: RequestFactory, Error == R.Error {
        fatalError("abstract needs override")
    }
}

final private class RefreshTokenBox<T: StopTheLine>: AbstractRefreshToken<T.Error> {
    private var concrete: T

    init(_ concrete: T) {
        self.concrete = concrete
    }

    override func makeRequest<R>(_ originalFactory: R) -> Callback<Ignorable> where Error == R.Error, R: RequestFactory {
        return concrete.makeRequest(originalFactory)
    }

    override func action(for error: Error, with info: RequestInfo) -> StopTheLineAction {
        return concrete.action(for: error, with: info)
    }
}
