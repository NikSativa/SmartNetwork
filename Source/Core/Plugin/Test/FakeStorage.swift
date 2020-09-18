import Quick
import Spry

@testable import NRequest

public final
class FakeStorage: Storage, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case tokenForKey = "token(forKey:)"
        case saveToken = "saveToken(_:forKey:)"
        case removeToken = "removeToken(forKey:)"
    }

    public init() {
    }

    public func token(forKey key: String) -> String? {
        return spryify(arguments: key)
    }

    public func saveToken(_ token: String, forKey key: String) {
        return spryify(arguments: token, key)
    }

    public func removeToken(forKey key: String) {
        return spryify(arguments: key)
    }
}
