import Quick
import Spry

@testable import NRequest

final
class FakeTokenStorage: TokenStorage, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case token
        case isEmpty
    }

    var token: String? {
        return spryify()
    }

    var isEmpty: Bool {
        return spryify()
    }
}

final
class FakeMutatedTokenStorage: MutatedTokenStorage, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case token
        case isEmpty
        case setToken = "set(_:)"
        case clear = "clear()"
    }

    var token: String? {
        return spryify()
    }

    var isEmpty: Bool {
        return spryify()
    }

    func set(_ token: String) {
        return spryify(arguments: token)
    }

    func clear() {
        return spryify()
    }
}
