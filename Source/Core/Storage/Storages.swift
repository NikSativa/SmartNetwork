import Foundation

public enum Storages {
    public class UserDefaults: Storage {
        public typealias Key = String
        public typealias Value = String
        
        private let storage: Foundation.UserDefaults
        
        public init(storage: Foundation.UserDefaults) {
            self.storage = storage
        }
        
        
        public func set(_ value: Value, for key: Key) {
            storage.set(value, forKey: key)
        }
        
        public func value(for key: Key) -> Value? {
            return storage.string(forKey: key)
        }
        
        public func remove(by key: Key) {
            storage.removeObject(forKey: key)
        }
    }
    
    public class Keyed<Value> {
        public typealias Key = String
        
        private let key: Key
        private let storage: AnyStorage<Key, Value>
        
        public init(storage: AnyStorage<Key, Value>, key: Key) {
            self.storage = storage
            self.key = key
        }
        
        public var value: Value? {
            get {
                storage.value(for: key)
            }
            set {
                if let newValue = newValue {
                    storage.set(newValue, for: key)
                } else {
                    storage.remove(by: key)
                }
            }
        }
        
        public func remove() {
            storage.remove(by: key)
        }
    }
    
    public class InMemory<Key: Hashable, Value>: Storage {
        private var cache: [Key: Value]
        
        public init(cache: [Key: Value] = [:]) {
            self.cache = cache
        }
        
        public func set(_ value: Value, for key: Key) {
            cache[key] = value
        }
        
        public func value(for key: Key) -> Value? {
            return cache[key]
        }
        
        public func remove(by key: Key) {
            cache[key] = nil
        }
    }
}
