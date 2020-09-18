import Foundation

public protocol AnyError: Error, Equatable {
    init?(_ error: Swift.Error)
    init(_ error: EquatableError)
}

public extension AnyError {
    static func wrap(_ error: Error) -> Self {
        if let error = error as? Self {
            return error
        } else if let error = Self.init(error) {
            return error
        }
        return Self.init(EquatableError(error))
    }
}
