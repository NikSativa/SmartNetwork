import Foundation

public protocol AnyError: Error, Equatable {
    init?(_ error: Swift.Error)
    init(_ error: EquatableError)
}

public extension AnyError {
    static func wrap(_ error: Error) -> Self {
        if let error = error as? Self {
            return error
        } else if let error = Self(error) {
            return error
        }
        return Self(EquatableError(error))
    }
}

public extension Error {
    func wrap<T: AnyError>() -> T {
        return .wrap(self)
    }
}
