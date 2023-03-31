import Foundation

/// reference type to exclude 'copy on write'
public final class UserInfo {
    public private(set) var values: [String: Any]

    public init(_ values: [String: Any] = [:]) {
        self.values = values
    }

    public var isEmpty: Bool {
        return values.isEmpty
    }

    public subscript<T>(_ key: String) -> T? {
        get {
            return values[key] as? T
        }
        set {
            values[key] = newValue
        }
    }

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
