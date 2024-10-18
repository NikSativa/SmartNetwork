import Foundation

/// The AddressDetails struct in Swift represents a URL and contains specific components to define the address details.
/// This struct is intended to encapsulate detailed information about a URL, such as scheme, host, port,
/// path components, query items, and fragment for constructing and processing URLs effectively within the system.
public struct AddressDetails: Hashable {
    public let scheme: Scheme?
    public let host: String
    public let port: Int?
    public let path: [String]
    public let queryItems: QueryItems
    public let fragment: String?

    public init(scheme: Scheme? = .https,
                host: String,
                port: Int? = nil,
                path: [String] = [],
                queryItems: QueryItems = [],
                fragment: String? = nil) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.queryItems = queryItems
        self.fragment = fragment
    }
}

public extension AddressDetails {
    init(url: URL) throws {
        let components = try URLComponents(url: url, resolvingAgainstBaseURL: true).unwrap(orThrow: RequestEncodingError.brokenURL)

        self.scheme = components.scheme.sdk
        self.host = try components.host.unwrap(orThrow: RequestEncodingError.brokenHost)
        self.port = components.port
        self.path = components.path.components(separatedBy: "/")
        self.fragment = components.fragment

        let items: [QueryItems.Element] = (components.queryItems ?? []).map {
            return .init(key: $0.name, value: $0.value)
        }
        self.queryItems = .init(items)
    }

    init(string: String) throws {
        let url = try URL(string: string).unwrap(orThrow: RequestEncodingError.brokenURL)
        try self.init(url: url)
    }
}

private extension String? {
    var sdk: Scheme? {
        guard let self, !self.isEmpty else {
            return nil
        }

        if self.hasPrefix("https") {
            return .https
        } else if self.hasPrefix("http") {
            return .http
        } else {
            return .other(self)
        }
    }
}

#if swift(>=6.0)
extension AddressDetails: Sendable {}
#endif
