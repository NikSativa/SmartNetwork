import Quick
import Spry
import NRequest

@testable import NRequest

final
class FakePluginProvider: PluginProvider, Spryable {
    enum ClassFunction: String, StringRepresentable {
        case empty
    }

    enum Function: String, StringRepresentable {
        case plugins = "plugins()"
    }

    func plugins() -> [Plugin] {
        return spryify()
    }
}
