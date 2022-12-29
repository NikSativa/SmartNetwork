import Foundation
import NSpry
@testable import NRequest

public final class FakeURLRequestable: URLRequestable, Spryable {
    public func value(forHTTPHeaderField field: String) -> String? {
        return spryify(arguments: field)
    }

    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case original
        case allHTTPHeaderFields
        case url
        case body
        case addValue = "addValue(_:forHTTPHeaderField:)"
        case setValue = "setValue(_:forHTTPHeaderField:)"
        case value = "value(forHTTPHeaderField:)"
    }

    public init() {}

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

    public var body: Data? {
        return spryify()
    }

    public func addValue(_ value: String, forHTTPHeaderField field: String) {
        return spryify(arguments: value, field)
    }

    public func setValue(_ value: String?, forHTTPHeaderField field: String) {
        return spryify(arguments: value, field)
    }
}
