import Foundation

public class AnyStorage<Key: Hashable, Value> {
    private let box: AbstractStorage<Key, Value>

    public init<S: Storage>(_ storage: S) where S.Key == Key, S.Value == Value {
        box = StorageBox(storage)
    }

    public func set(_ value: Value, for key: Key) {
        box.set(value, for: key)
    }

    public func value(for key: Key) -> Value? {
        return box.value(for: key)
    }

    public func remove(by key: Key) {
        box.remove(by: key)
    }
}

private class AbstractStorage<Key: Hashable, Value>: Storage {
    func set(_ value: Value, for key: Key) {
        fatalError("abstract needs override")
    }

    func value(for key: Key) -> Value? {
        fatalError("abstract needs override")
    }

    func remove(by key: Key) {
        fatalError("abstract needs override")
    }
}

final
private class StorageBox<S: Storage>: AbstractStorage<S.Key, S.Value> {
    private let concrete: S

    init(_ concrete: S) {
        self.concrete = concrete
    }

    override func set(_ value: Value, for key: Key) {
        concrete.set(value, for: key)
    }

    override func value(for key: Key) -> Value? {
        return concrete.value(for: key)
    }

    override func remove(by key: Key) {
        concrete.remove(by: key)
    }
}
