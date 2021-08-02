import Foundation
import NSpry
import NRequest

@testable import NRequest

public final class FakePluginProvider: PluginProvider, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case plugins = "plugins()"
    }

    public init() {
    }

    public func plugins() -> [Plugin] {
        return spryify()
    }
}
