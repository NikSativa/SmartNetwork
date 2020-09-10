import Quick
import Spry

@testable import NRequest

final
class FakeStorage: Storage, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case tokenForKey = "token(forKey:)"
        case saveToken = "saveToken(_:forKey:)"
        case removeToken = "removeToken(forKey:)"
    }

    func token(forKey key: String) -> String? {
        return spryify(arguments: key)
    }

    func saveToken(_ token: String, forKey key: String) {
        return spryify(arguments: token, key)
    }

    func removeToken(forKey key: String) {
        return spryify(arguments: key)
    }
}
