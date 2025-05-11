import Foundation

/// A strongly typed key used to access values in a `UserInfo` dictionary.
///
/// `UserInfoKey` acts as a namespaced wrapper around raw string values, enabling safer and more descriptive
/// access to metadata passed through the request lifecycle.
public struct UserInfoKey: RawRepresentable, Hashable, ExpressibleByStringLiteral, SmartSendable {
    public let rawValue: String

    /// Creates a new user info key from the given raw string value.
    ///
    /// - Parameter rawValue: A unique string used to identify the key.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Allows string literals to be used as `UserInfoKey` values.
    ///
    /// Enables syntactic sugar like `let key: UserInfoKey = "example"`.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomDebugStringConvertible

extension UserInfoKey: CustomDebugStringConvertible {
    /// Returns a debug-friendly string representation of the key.
    public var debugDescription: String {
        return rawValue
    }
}

// MARK: - CustomStringConvertible

extension UserInfoKey: CustomStringConvertible {
    /// Returns the string representation of the key.
    public var description: String {
        return rawValue
    }
}
