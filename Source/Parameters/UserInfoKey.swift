import Foundation

/// A type that represents a namespace of keys for a value in a `UserInfo` dictionary.
public struct UserInfoKey: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomDebugStringConvertible

extension UserInfoKey: CustomDebugStringConvertible {
    public var debugDescription: String {
        return rawValue
    }
}

// MARK: - CustomStringConvertible

extension UserInfoKey: CustomStringConvertible {
    public var description: String {
        return rawValue
    }
}

#if swift(>=6.0)
extension UserInfoKey: Sendable {}
#endif
