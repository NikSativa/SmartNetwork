import Foundation

public struct URLRepresentation: Equatable {
    public let scheme: Address.Scheme?
    public let host: String
    public let port: Int?
    public let path: [String]
    public let queryItems: QueryItems
    public let fragment: String?

    public init(scheme: Address.Scheme? = .https,
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

    public init(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

        self.scheme = Address.Scheme(components.scheme)
        self.host = components.host ?? ""
        self.port = components.port
        self.path = components.path.components(separatedBy: "/")
        self.fragment = components.fragment

        let items: [QueryItems.Element] = (components.queryItems ?? []).map {
            return .init(key: $0.name, value: $0.value)
        }
        self.queryItems = .init(items)
    }

    public func append(_ pathComponent: String) -> Self {
        return self + pathComponent
    }

    public func append(_ queryItems: QueryItems) -> Self {
        return self + queryItems
    }

    public static func +(lhs: Self, rhs: QueryItems) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path,
                    queryItems: lhs.queryItems + rhs,
                    fragment: lhs.fragment)
    }

    public static func +(lhs: Self, rhs: [String]) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path + rhs,
                    queryItems: lhs.queryItems,
                    fragment: lhs.fragment)
    }

    public static func +(lhs: Self, rhs: String) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path + [rhs],
                    queryItems: lhs.queryItems,
                    fragment: lhs.fragment)
    }
}

private extension Address.Scheme {
    init?(_ string: String?) {
        guard let string, !string.isEmpty else {
            return nil
        }

        if string.hasPrefix("https") {
            self = .https
        } else if string.hasPrefix("http") {
            self = .http
        } else {
            self = .other(string)
        }
    }
}
