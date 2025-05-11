import Foundation
import Threading

/// A container for storing key-value metadata shared throughout the request lifecycle.
///
/// `UserInfo` is a reference type to avoid unnecessary copying and supports dynamic metadata lookup using `UserInfoKey`.
/// It is not thread-safe by default, but atomic operations are used for internal synchronization.
public final class UserInfo {
    /// The internal dictionary used to store user-provided key-value pairs.
    ///
    /// Access is synchronized using an atomic property wrapper to ensure safe concurrent reads and writes.
    @Atomic(mutex: .unfair, read: .sync, write: .sync)
    public private(set) var values: [UserInfoKey: Any] = [:]

    /// Initializes a new instance with the provided values.
    public init(_ values: [UserInfoKey: Any] = [:]) {
        self.values = values
    }

    /// Returns `true` if no values are stored in the `UserInfo`.
    public var isEmpty: Bool {
        return $values.mutate { values in
            return values.isEmpty
        }
    }

    /// Accesses the value associated with the given key.
    ///
    /// - Note: Use the generic type `T` to cast the value to the expected type.
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

    /// Retrieves the value associated with the given key, cast to a specific type.
    ///
    /// - Parameters:
    ///   - type: The expected type of the value (inferred by default).
    ///   - key: The key associated with the value.
    /// - Returns: The typed value, or `nil` if no matching value is found.
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
    /// Attempts to convert the dictionary into a pretty-printed JSON string for debugging purposes.
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
/// Converts a value to a string using a JSON encoder or string protocol conformance.
///
/// - Parameters:
///   - value: The value to convert.
///   - encoder: A `JSONEncoder` used for encoding `Encodable` values.
/// - Returns: A string representation of the value.
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
