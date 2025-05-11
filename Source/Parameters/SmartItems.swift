import Foundation

/// Type representing query items. It is an array of key-value pairs.
public typealias QueryItems = SmartItems<String?>

/// The header fields of a network request.
public typealias HeaderFields = SmartItems<String>

/// A collection of key-value pairs represented as an array of `SmartItem` elements.
///
/// `SmartItems` is a generic structure used for organizing, accessing, and transforming ordered key-value data.
/// It is commonly used for headers, query items, and other key-value use cases within SmartNetwork.
public struct SmartItems<T: Hashable>: Hashable {
    public private(set) var rawValues: [SmartItem<T>]
}

public extension SmartItems {
    /// Creates a new instance from an array of `SmartItem` values.
    ///
    /// - Parameter items: An array of key-value pairs.
    init(_ items: [SmartItem<T>]) {
        self.rawValues = items
    }

    /// Creates a new instance from a dictionary of keys and values.
    ///
    /// - Parameter items: A dictionary to convert into an array of `SmartItem` values.
    init(_ items: [String: T]) {
        self.rawValues = items.map(SmartItem.init(key:value:))
    }

    /// Creates an empty collection of `SmartItem` values.
    init() {
        self.rawValues = []
    }

    /// A Boolean value indicating whether the collection is empty.
    var isEmpty: Bool {
        return rawValues.isEmpty
    }

    /// The number of items in the collection.
    var count: Int {
        return rawValues.count
    }

    /// Appends a new key-value pair to the end of the collection.
    ///
    /// - Parameters:
    ///   - key: The key to add.
    ///   - value: The associated value.
    mutating func append(key: String, value: T) {
        rawValues.append(.init(key: key, value: value))
    }

    /// Inserts or replaces the element with the same key.
    ///
    /// If an item with the given key already exists, it will be removed and replaced by the new one.
    /// - Parameter item: The key-value pair to insert or update.
    mutating func set(_ item: SmartItem<T>) {
        rawValues = rawValues.filter {
            return $0.key != item.key
        }
        rawValues.append(item)
    }

    /// Inserts or replaces the value for a given key.
    ///
    /// - Parameters:
    ///   - key: The key to insert or update.
    ///   - value: The value to associate with the key.
    mutating func set(_ key: String, value: T) {
        set(.init(key: key, value: value))
    }

    /// Removes all elements from the collection.
    mutating func removeAll() {
        rawValues = []
    }

    /// Removes all elements that match the specified key.
    ///
    /// - Parameter key: The key of the elements to remove.
    mutating func removeAll(byKey key: String) {
        rawValues = rawValues.filter {
            return $0.key != key
        }
    }

    /// Accesses the first value associated with the given key.
    ///
    /// Assigning `nil` removes all items with the specified key.
    /// - Parameter key: The key to look up.
    /// - Returns: The associated value, or `nil` if no match is found.
    subscript(_ key: String) -> T? {
        get {
            return rawValues.first {
                return $0.key == key
            }?.value
        }
        set {
            if let newValue {
                set(.init(key: key, value: newValue))
            } else {
                removeAll(byKey: key)
            }
        }
    }

    /// Returns a new `SmartItems` instance containing only the elements that satisfy the given predicate.
    ///
    /// - Parameter isIncluded: A closure that takes an element and returns a Boolean value indicating
    ///   whether the element should be included in the returned collection.
    /// - Returns: A filtered `SmartItems` collection.
    func filter(_ isIncluded: (SmartItem<T>) throws -> Bool) rethrows -> Self {
        let filtered = try rawValues.filter(isIncluded)
        return .init(filtered)
    }

    /// Returns a new `SmartItems` collection by concatenating two collections.
    ///
    /// - Parameters:
    ///   - lhs: The first collection.
    ///   - rhs: The second collection.
    /// - Returns: A new collection containing elements from both input collections.
    @inline(__always)
    static func +(lhs: Self, rhs: Self) -> Self {
        return .init(lhs.rawValues + rhs.rawValues)
    }
}

internal extension SmartItems where T == String {
    /// Converts the key-value pairs into a dictionary, merging duplicate keys by joining their values with commas.
    func mapToResponse() -> [String: String]
    where T == String {
        let keysAndValues: [(String, String)] = rawValues.map { ($0.key, $0.value) }
        let fields: [String: String] = .init(keysAndValues) { a, b in
            return [a, b].joined(separator: ",")
        }
        return fields
    }
}

internal extension SmartItems where T == String? {
    /// Converts the key-value pairs into a dictionary, joining multiple values and filtering out nils.
    func mapToDescription() -> [String: String?] {
        let keysAndValues: [(String, String?)] = rawValues.map { ($0.key, $0.value) }
        let fields: [String: String?] = .init(keysAndValues) { a, b in
            return [a, b].filterNils().joined(separator: ",")
        }
        return fields
    }
}

// MARK: - Sequence

extension SmartItems: Sequence {
    public struct Iterator: IteratorProtocol {
        private var index: Int
        private let items: [SmartItem<T>]

        internal init(items: [SmartItem<T>]) {
            self.index = 0
            self.items = items
        }

        public mutating func next() -> SmartItem<T>? {
            if index < items.count {
                let item = items[index]
                index += 1
                return item
            } else {
                return nil
            }
        }
    }

    public func makeIterator() -> Iterator {
        return .init(items: rawValues)
    }
}

// MARK: - CustomDebugStringConvertible

extension SmartItems: CustomDebugStringConvertible {
    public var debugDescription: String {
        return rawValues.debugDescription
    }
}

// MARK: - CustomStringConvertible

extension SmartItems: CustomStringConvertible {
    public var description: String {
        return rawValues.description
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension SmartItems: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, T)...) {
        self.rawValues = elements.map(SmartItem.init(key:value:))
    }
}

#if swift(>=6.0)
extension SmartItems: @unchecked Sendable {}
#endif
