import Foundation

public class URLRequestable {
    private(set) var original: URLRequest

    public required init(_ original: URLRequest) {
        self.original = original
    }

    public var url: URL? {
        get {
            original.url
        }
        set {
            original.url = newValue
        }
    }

    public func addValue(_ value: String, forHTTPHeaderField field: String) {
        original.addValue(value, forHTTPHeaderField: field)
    }

    public func setValue(_ value: String?, forHTTPHeaderField field: String) {
        original.setValue(value, forHTTPHeaderField: field)
    }
}

public struct RequestInfo {
    public let request: URLRequestable
    public let parameters: Parameters
}

extension RequestInfo {
    init(request: URLRequest,
         parameters: Parameters) {
        self.request = .init(request)
        self.parameters = parameters
    }
}
