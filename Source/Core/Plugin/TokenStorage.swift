import Foundation

public protocol TokenStorage {
    var token: String? { get }
    var isEmpty: Bool { get }
}

public protocol MutatedTokenStorage: TokenStorage {
    func set(_ token: String)
    func clear()
}

extension Impl {
    final
    class TokenStorage {
        private let storage: Storage
        private let key: String

        init(storage: Storage, key: String) {
            self.storage = storage
            self.key = key
        }
    }
}

extension Impl.TokenStorage: TokenStorage {
    var token: String? {
        return storage.token(forKey: key)
    }

    var isEmpty: Bool {
        return token.map { $0.isEmpty } ?? true
    }
}

extension Impl.TokenStorage: MutatedTokenStorage {
    func set(_ token: String) {
        storage.saveToken(token, forKey: key)
    }

    func clear() {
        storage.removeToken(forKey: key)
    }
}
