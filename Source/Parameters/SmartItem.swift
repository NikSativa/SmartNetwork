import Foundation

/// Represents a key-value pair used in query strings or HTTP headers.
///
/// `SmartItem` is a flexible abstraction for encoding URL query parameters or header fields.
/// It supports values that may be `nil` and handles formatting nuances for different contexts:
///
/// - When used in a query string: keys may repeat with different values (e.g., `?key=value1&key=value2`).
/// - When used as HTTP headers: values for the same key may be concatenated (e.g., `key: value1,value2`).
public struct SmartItem<T: Hashable>: Hashable {
    /// The key component of the item (e.g., query parameter or header name).
    public let key: String
    /// The value component of the item. May be optional or representable as a string.
    public let value: T

    /// Initializes a new `SmartItem` with a specified key and value.
    ///
    /// - Parameters:
    ///   - key: The key of the item.
    ///   - value: The associated value.
    public init(key: String, value: T) {
        self.key = key
        self.value = value
    }

    /// Returns a readable string representation in the format `key: value`,
    /// unwrapping optional string values for clarity.
    private var myDescription: String {
        var value = "\(value)"
        if value.hasPrefix("Optional(\"") {
            value = String(value.dropFirst("Optional(\"".count).dropLast(2))
        }
        return [key, value].joined(separator: ": ")
    }
}

// MARK: - CustomStringConvertible

extension SmartItem: CustomStringConvertible {
    public var description: String {
        return myDescription
    }
}

// MARK: - CustomDebugStringConvertible

extension SmartItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        return myDescription
    }
}

#if swift(>=6.0)
extension SmartItem: Sendable where T: Sendable {}
#endif
