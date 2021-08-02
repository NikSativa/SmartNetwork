import Foundation

public protocol URLRequestable {
    var original: URLRequest { get }
    var allHTTPHeaderFields: [String: String] { get }
    var url: URL? { get set }
    var body: Data? { get }

    mutating func addValue(_ value: String, forHTTPHeaderField field: String)
    mutating func setValue(_ value: String?, forHTTPHeaderField field: String)
}

extension Impl {
    struct URLRequestable {
        private(set) var original: URLRequest

        init(_ original: URLRequest) {
            self.original = original
        }
    }
}

extension Impl.URLRequestable: URLRequestable {
    var allHTTPHeaderFields: [String: String] {
        original.allHTTPHeaderFields ?? [:]
    }

    var url: URL? {
        get {
            original.url
        }
        set {
            original.url = newValue
        }
    }

    var body: Data? {
        original.httpBody
    }

    mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        original.addValue(value, forHTTPHeaderField: field)
    }

    mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        original.setValue(value, forHTTPHeaderField: field)
    }
}
