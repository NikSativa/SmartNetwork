import Foundation

public struct URLRequestable: Hashable {
    private(set) var original: URLRequest

    public init(_ original: URLRequest) {
        self.original = original
    }

    public var allHTTPHeaderFields: [String: String] {
        original.allHTTPHeaderFields ?? [:]
    }

    public var url: URL? {
        get {
            original.url
        }
        set {
            original.url = newValue
        }
    }

    public mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        original.addValue(value, forHTTPHeaderField: field)
    }

    public mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        original.setValue(value, forHTTPHeaderField: field)
    }

    public static func == (lhs: URLRequestable, rhs: URLRequestable) -> Bool {
        lhs.original == rhs.original
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(original)
    }
}

public struct RequestInfo {
    public var request: URLRequestable
    public let parameters: Parameters
}

extension RequestInfo {
    init(request: URLRequest,
         parameters: Parameters) {
        self.request = .init(request)
        self.parameters = parameters
    }
}
