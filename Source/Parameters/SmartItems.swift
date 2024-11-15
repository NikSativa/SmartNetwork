import Foundation

/// Type representing query items. It is an array of key-value pairs.
public typealias QueryItems = SmartItems<String?>

/// The header fields of a network request.
public typealias HeaderFields = SmartItems<String>

/// The ``SmartItem`` struct in Swift represents a key-value pairs collection.
/// This struct is intended to encapsulate a pair of key and value for constructing and processing key-value pairs effectively within the system.
public struct SmartItems<T: Hashable>: Hashable {
    private var rawValues: [SmartItem<T>]
}

public extension SmartItems {
    /// Initializes a new instance with the provided items.
    init(_ items: [SmartItem<T>]) {
        self.rawValues = items
    }

    /// Initializes a new instance with the provided items.
    init(_ items: [String: T]) {
        self.rawValues = items.map(SmartItem.init(key:value:))
    }

    /// Initializes a new instance with the provided items.
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

    /// Adds a new element at the end of the array.
    mutating func append(key: String, value: T) {
        rawValues.append(.init(key: key, value: value))
    }

    /// Sets a new element at the end of the array.
    ///
    /// - Important: If the key already exists, it will be replaced.
    mutating func set(_ item: SmartItem<T>) {
        rawValues = rawValues.filter {
            return $0.key != item.key
        }
        rawValues.append(item)
    }

    /// Sets a new element at the end of the array.
    ///
    /// - Important: If the key already exists, it will be replaced.
    mutating func set(_ key: String, value: T) {
        set(.init(key: key, value: value))
    }

    /// Removes all elements from the collection.
    mutating func removeAll() {
        rawValues = []
    }

    /// Removes all elements from the collection with the specified key.
    mutating func removeAll(byKey key: String) {
        rawValues = rawValues.filter {
            return $0.key != key
        }
    }

    /// Subscript to get or set an item by key.
    /// - Parameter key: The key to search for.
    /// - Returns: The value of the first element of the sequence that satisfies the given key.
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

    /// Filters the elements of the collection.
    func filter(_ isIncluded: (SmartItem<T>) throws -> Bool) rethrows -> Self {
        let filtered = try rawValues.filter(isIncluded)
        return .init(filtered)
    }

    /// Returns new collection with the elements of both collections.
    @inline(__always)
    static func +(lhs: Self, rhs: Self) -> Self {
        return .init(lhs.rawValues + rhs.rawValues)
    }
}

internal extension SmartItems where T == String {
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
