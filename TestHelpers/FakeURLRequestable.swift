import Foundation
import Spry

@testable import NRequest

final public
class FakeURLRequestable: URLRequestable, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case original
        case allHTTPHeaderFields
        case url
        case addValue = "addValue(_:forHTTPHeaderField:)"
        case setValue = "setValue(_:forHTTPHeaderField:)"
    }

    public init() {
    }

    public var original: URLRequest {
        return spryify()
    }

    public var allHTTPHeaderFields: [String: String] {
        return spryify()
    }

    public var url: URL? {
        get {
            return stubbedValue()
        }
        set {
            return recordCall(arguments: newValue)
        }
    }

    public func addValue(_ value: String, forHTTPHeaderField field: String) {
        return spryify(arguments: value, field)
    }

    public func setValue(_ value: String?, forHTTPHeaderField field: String) {
        return spryify(arguments: value, field)
    }
}
