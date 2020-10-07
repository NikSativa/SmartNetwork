import Foundation
import Spry

@testable import NRequest

public final
class FakeAuthTokenProvider: AuthTokenProvider, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case token = "token()"
    }

    public init() {
    }

    public func token() -> String? {
        return spryify()
    }
}
