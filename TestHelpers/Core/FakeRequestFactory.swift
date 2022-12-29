import Foundation
import NSpry
@testable import NRequest

public final class FakeRequestFactory: RequestFactory, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case make = "make(for:pluginContext:)"
    }

    public init() {}

    public func make(for parameters: Parameters,
                     pluginContext: PluginProvider?) -> Request {
        return spryify(arguments: parameters, pluginContext)
    }
}
