import Foundation
import Spry

@testable import NRequest

public final
class FakeStorage<Key: Hashable, Value>: Storage, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case set = "set(_:for)"
        case value = "value(for:)"
        case remove = "remove(by:)"
    }

    public init() {
    }

    public func set(_ value: Value, for key: Key) {
        return spryify(arguments: value, key)
    }

    public func value(for key: Key) -> Value? {
        return spryify(arguments: key)
    }

    public func remove(by key: Key) {
        return spryify(arguments: key)
    }
}
