import Foundation
import NCallback

public protocol RefreshToken {
    associatedtype Error: AnyError
    func makeRequest<R: RequestFactory>(_ originalFactory: R) -> Callback<Ignorable> where R.Error == Error
    func shouldRefresh(_ error: Error) -> Bool
}

public extension RefreshToken {
    func toAny() -> AnyRefreshToken<Error> {
        if let self = self as? AnyRefreshToken<Error> {
            return self
        }

        return AnyRefreshToken(self)
    }
}

final
public class AnyRefreshToken<Error: AnyError>: RefreshToken {
    private let box: AbstractRefreshToken<Error>

    public init<K: RefreshToken>(_ provider: K) where K.Error == Error {
        self.box = RefreshTokenBox(provider)
    }

    public func makeRequest<R>(_ originalFactory: R) -> Callback<Ignorable> where R : RequestFactory, Error == R.Error {
        box.makeRequest(originalFactory)
    }

    public func shouldRefresh(_ error: Error) -> Bool {
        box.shouldRefresh(error)
    }
}

private class AbstractRefreshToken<Error: AnyError>: RefreshToken {
    func shouldRefresh(_ error: Error) -> Bool {
        fatalError("abstract needs override")
    }

    func makeRequest<R>(_ originalFactory: R) -> Callback<Ignorable> where R : RequestFactory, Error == R.Error {
        fatalError("abstract needs override")
    }
}

final
private class RefreshTokenBox<T: RefreshToken>: AbstractRefreshToken<T.Error> {
    private var concrete: T

    init(_ concrete: T) {
        self.concrete = concrete
    }

    override func makeRequest<R>(_ originalFactory: R) -> Callback<Ignorable> where Error == R.Error, R : RequestFactory {
        concrete.makeRequest(originalFactory)
    }

    override func shouldRefresh(_ error: Error) -> Bool {
        concrete.shouldRefresh(error)
    }
}
