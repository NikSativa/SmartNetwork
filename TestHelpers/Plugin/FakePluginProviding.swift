import Foundation
import NSpry

@testable import NRequest

public final class FakePluginProviding: PluginProviding, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case plugins = "plugins()"
    }

    public init() {}

    public func plugins() -> [Plugin] {
        return spryify()
    }
}