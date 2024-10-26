import Foundation

/// A type that stores arbitrary user information. It is a reference type to avoid 'copy on write'. It is not thread safe.
public final class UserInfo {
    /// The values stored in the user info.
    public private(set) var values: [String: Any]

    /// Initializes a new instance with the provided values.
    public init(_ values: [String: Any] = [:]) {
        self.values = values
    }

    /// Indicates whether the user info is empty.
    public var isEmpty: Bool {
        return values.isEmpty
    }

    /// Accesses the value associated with the given key for reading and writing.
    public subscript<T>(_ key: String) -> T? {
        get {
            return values[key] as? T
        }
        set {
            values[key] = newValue
        }
    }

    /// Accesses the value associated with the given key.
    public func value<T>(of _: T.Type = T.self, for key: String) -> T? {
        return values[key] as? T
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension UserInfo: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (String, Any)...) {
        self.init(.init(uniqueKeysWithValues: elements))
    }
}

#if swift(>=6.0)
extension UserInfo: @unchecked Sendable {}
#endif
