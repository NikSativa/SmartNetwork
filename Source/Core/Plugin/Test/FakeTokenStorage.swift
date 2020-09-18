import Quick
import Spry

@testable import NRequest

public final
class FakeTokenStorage: TokenStorage, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case token
        case isEmpty
    }

    public init() {
    }

    public var token: String? {
        return spryify()
    }

    public var isEmpty: Bool {
        return spryify()
    }
}

public final
class FakeMutatedTokenStorage: MutatedTokenStorage, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case token
        case isEmpty
        case setToken = "set(_:)"
        case clear = "clear()"
    }

    public init() {
    }

    public var token: String? {
        return spryify()
    }

    public var isEmpty: Bool {
        return spryify()
    }

    public func set(_ token: String) {
        return spryify(arguments: token)
    }

    public func clear() {
        return spryify()
    }
}
