import Foundation
import NSpry

@testable import NRequest

public final
class FakeBearerTokenProvider: BearerTokenProvider, Spryable {
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
