import Foundation

public protocol URLRequestable {
    var original: URLRequest { get }
    var allHTTPHeaderFields: [String: String] { get }
    var url: URL? { get set }
    var body: Data? { get }

    func value(forHTTPHeaderField field: String) -> String?
    mutating func addValue(_ value: String, forHTTPHeaderField field: String)
    mutating func setValue(_ value: String?, forHTTPHeaderField field: String)
}

// MARK: - Impl.URLRequestable

extension Impl {
    struct URLRequestable {
        private(set) var original: URLRequest

        init(_ original: URLRequest) {
            self.original = original
        }
    }
}

// MARK: - Impl.URLRequestable + URLRequestable

extension Impl.URLRequestable: URLRequestable {
    var allHTTPHeaderFields: [String: String] {
        return original.allHTTPHeaderFields ?? [:]
    }

    var url: URL? {
        get {
            return original.url
        }
        set {
            original.url = newValue
        }
    }

    var body: Data? {
        return original.httpBody
    }

    func value(forHTTPHeaderField field: String) -> String? {
        return original.value(forHTTPHeaderField: field)
    }

    mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        original.addValue(value, forHTTPHeaderField: field)
    }

    mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        original.setValue(value, forHTTPHeaderField: field)
    }
}
