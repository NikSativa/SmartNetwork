import Quick
import Spry

@testable import NRequest

final
class FakeAuthTokenProvider: AuthTokenProvider, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case token = "token()"
    }

    func token() -> String? {
        return spryify()
    }
}
