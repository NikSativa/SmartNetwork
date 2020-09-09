import Foundation

public protocol TokenKey {
    static var key: String { get }
}

public protocol Storage {
    func token(forKey key: String) -> String?
    func saveToken(_ token: String, forKey key: String)
    func removeToken(forKey key: String)
}

public class Token<T: TokenKey> {
    public var value: String? {
        return defaults.token(forKey: key)
    }

    fileprivate let defaults: Storage
    fileprivate var key: String {
        return T.key
    }

    public init(defaults: Storage) {
        self.defaults = defaults
    }

    public var isEmpty: Bool {
        return value.map { $0.isEmpty } ?? true
    }
}

public class MutableToken<T: TokenKey>: Token<T> {
    public func set(_ token: String) {
        defaults.saveToken(token, forKey: key)
    }

    public func clear() {
        defaults.removeToken(forKey: key)
    }
}
