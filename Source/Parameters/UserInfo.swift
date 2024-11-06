import Foundation

/// A type that stores arbitrary user information. It is a reference type to avoid 'copy on write'. It is not thread safe.
public final class UserInfo {
    /// The values stored in the user info.
    public private(set) var values: [UserInfoKey: Any]

    /// Initializes a new instance with the provided values.
    public init(_ values: [UserInfoKey: Any] = [:]) {
        self.values = values
    }

    /// Indicates whether the user info is empty.
    public var isEmpty: Bool {
        return values.isEmpty
    }

    /// Accesses the value associated with the given key for reading and writing.
    public subscript<T>(_ key: UserInfoKey) -> T? {
        get {
            return values[key] as? T
        }
        set {
            values[key] = newValue
        }
    }

    /// Accesses the value associated with the given key.
    public func value<T>(of _: T.Type = T.self, for key: UserInfoKey) -> T? {
        return values[key] as? T
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension UserInfo: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (UserInfoKey, Any)...) {
        self.init(.init(uniqueKeysWithValues: elements))
    }
}

// MARK: - CustomDebugStringConvertible, CustomStringConvertible

extension UserInfo: CustomDebugStringConvertible, CustomStringConvertible {
    public var description: String {
        return makeDescription() ?? values.description
    }

    public var debugDescription: String {
        return makeDescription() ?? values.debugDescription
    }

    private func makeDescription() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]

        let json: [UserInfoKey: String] = values.mapValues { value in
            if let enc = value as? Encodable,
               let data = try? encoder.encode(enc),
               let text = String(data: data, encoding: .utf8) {
                return text
            }
            return "\(value)"
        }

        guard let data = try? encoder.encode(json) else {
            return nil
        }

        let text = String(data: data, encoding: .utf8)
        return text
    }
}

#if swift(>=6.0)
extension UserInfo: @unchecked Sendable {}
#endif
