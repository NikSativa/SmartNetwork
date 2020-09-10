import Foundation

public protocol Storage {
    func token(forKey key: String) -> String?
    func saveToken(_ token: String, forKey key: String)
    func removeToken(forKey key: String)
}

extension UserDefaults: Storage {
    public func token(forKey key: String) -> String? {
        string(forKey: key)
    }

    public func saveToken(_ token: String, forKey key: String) {
        set(token, forKey: key)
    }

    public func removeToken(forKey key: String) {
        removeObject(forKey: key)
    }
}
