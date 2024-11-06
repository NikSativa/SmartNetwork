import Foundation

/// A type representing a query item. It is a key-value pair. The value can be `nil`.
/// Ex. `https://apple.com?key=value`
///
/// - Note: If item is representing a http header field, the values can be combined when the key is the same.
/// Ex. __`key: value1,value2`__
///
/// - Note: If item is representing a query item, the key can be represented multiple times when the values are different.
/// Ex. __`https://apple.com?key=value1&key=value2`__
public struct SmartItem<T: Hashable>: Hashable {
    /// The key of the query item.
    public let key: String
    /// The value of the query item.
    public let value: T

    /// Initializes a new instance with the provided key and value.
    public init(key: String, value: T) {
        self.key = key
        self.value = value
    }

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
