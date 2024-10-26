import Foundation

/// Type representing query items. It is an array of key-value pairs.
public typealias QueryItems = [SmartItem<String?>]

/// The header fields of a network request.
public typealias HeaderFields = [SmartItem<String>]

public extension Array {
    init<T>(_ items: [String: T])
        where T: Hashable, Element == SmartItem<T> {
        self.init(items.map(Element.init(key:value:)))
    }

    /// add new one
    mutating func append<T>(key: String, value: T)
    where T: Hashable, Element == SmartItem<T> {
        append(.init(key: key, value: value))
    }

    /// - NOTE: replacing all previously added items and add new one
    mutating func set<T>(_ item: SmartItem<T>)
    where T: Hashable, Element == SmartItem<T> {
        self = filter {
            return $0.key != item.key
        }
        append(item)
    }

    /// - NOTE: replacing all previously added items and add new one
    mutating func set<T>(key: String, value: T)
    where T: Hashable, Element == SmartItem<T> {
        set(.init(key: key, value: value))
    }

    mutating func removeAll<T>(byKey key: String)
    where T: Hashable, Element == SmartItem<T> {
        self = filter {
            return $0.key != key
        }
    }

    /// Subscript to get or set an item by key.
    subscript<T>(key: String) -> Element?
        where T: Hashable, Element == SmartItem<T> {
        get {
            return first {
                return $0.key == key
            }
        }
        set {
            if let newValue {
                set(newValue)
            } else {
                removeAll(byKey: key)
            }
        }
    }
}

internal extension Array {
    func mapToResponse() -> [String: String]
    where Element == SmartItem<String> {
        let keysAndValues: [(String, String)] = map { ($0.key, $0.value) }
        let fields: [String: String] = .init(keysAndValues) { a, b in
            return [a, b].joined(separator: ",")
        }
        return fields
    }
}

// MARK: - ExpressibleByDictionaryLiteral

#if hasFeature(RetroactiveAttribute) && swift(>=5.9)
extension QueryItems: @retroactive ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String?)...) {
        self = elements.map(Element.init(key:value:))
    }
}
#else
extension QueryItems: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String?)...) {
        self = elements.map(Element.init(key:value:))
    }
}
#endif

#if swift(>=6.0)
extension QueryItems: Sendable {}
#endif
