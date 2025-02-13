import Foundation
import Threading

/// A type that stores arbitrary user information. It is a reference type to avoid 'copy on write'. It is not thread safe.
public final class UserInfo {
    /// The values stored in the user info.
    @Atomic(mutex: .unfair, read: .sync, write: .sync)
    public private(set) var values: [UserInfoKey: Any] = [:]

    /// Initializes a new instance with the provided values.
    public init(_ values: [UserInfoKey: Any] = [:]) {
        self.values = values
    }

    /// Indicates whether the user info is empty.
    public var isEmpty: Bool {
        return $values.mutate { values in
            return values.isEmpty
        }
    }

    /// Accesses the value associated with the given key for reading and writing.
    public subscript<T>(_ key: UserInfoKey) -> T? {
        get {
            return $values.mutate { values in
                return values[key] as? T
            }
        }
        set {
            $values.mutate { values in
                values[key] = newValue
            }
        }
    }

    /// Accesses the value associated with the given key.
    public func value<T>(of _: T.Type = T.self, for key: UserInfoKey) -> T? {
        return $values.mutate { values in
            return values[key] as? T
        }
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension UserInfo: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (UserInfoKey, Any)...) {
        self.init(.init(uniqueKeysWithValues: elements))
    }
}

// MARK: - CustomDebugStringConvertible

extension UserInfo: CustomDebugStringConvertible {
    public var debugDescription: String {
        return values.prettyPrinted() ?? values.description
    }
}

// MARK: - CustomStringConvertible

extension UserInfo: CustomStringConvertible {
    public var description: String {
        return values.prettyPrinted() ?? values.description
    }
}

private extension Dictionary {
    func prettyPrinted() -> String? {
        if isEmpty {
            return "{}"
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]

        var json: [String: String] = [:]
        for (key, value) in self {
            json[convert(key, encoder: encoder)] = convert(value, encoder: encoder)
        }

        guard let data = try? encoder.encode(json) else {
            return nil
        }

        let text = String(data: data, encoding: .utf8)
        return text
    }
}

@inline(__always)
private func convert(_ value: Any, encoder: @autoclosure () -> JSONEncoder) -> String {
    let strValue: String
    if let str = value as? String {
        strValue = str
    } else if let value = value as? Encodable,
              let data = try? encoder().encode(value),
              let text = String(data: data, encoding: .utf8) {
        strValue = text
    } else if let value = value as? CustomStringConvertible {
        strValue = value.description
    } else if let value = value as? CustomDebugStringConvertible {
        strValue = value.debugDescription
    } else {
        strValue = "\(value)"
    }
    return strValue
}

#if swift(>=6.0)
extension UserInfo: @unchecked Sendable {}
#endif
