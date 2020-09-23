import Foundation

public enum StorageKind: Equatable {
    case inMemory
    case longTerm
    case userDefaults
    case keyed(String)
}

public protocol Storage {
    associatedtype Key: Hashable
    associatedtype Value

    func set(_ value: Value, for key: Key)
    func value(for key: Key) -> Value?
    func remove(by key: Key)

    func toAny() -> AnyStorage<Key, Value>
}

public extension Storage {
    func toAny() -> AnyStorage<Key, Value> {
        if let any = self as? AnyStorage<Key, Value> {
            return any
        }
        return AnyStorage(self)
    }
}
