import Foundation

public struct URLRepresentation: Equatable {
    public let scheme: Address.Scheme?
    public let host: String
    public let port: Int?
    public let path: [String]
    public let queryItems: QueryItems

    public init(scheme: Address.Scheme? = .https,
                host: String,
                port: Int? = nil,
                path: [String] = [],
                queryItems: QueryItems = [:]) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.queryItems = queryItems
    }

    public init(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

        self.scheme = Address.Scheme(components.scheme)
        self.host = components.host ?? ""
        self.port = components.port
        self.path = components.path.components(separatedBy: "/")
        self.queryItems = (components.queryItems ?? []).reduce(into: [:]) { $0[$1.name] = $1.value }
    }

    public func append(_ pathComponent: String) -> Self {
        self + pathComponent
    }

    public func append(_ queryItems: QueryItems) -> Self {
        self + queryItems
    }

    public static func +(lhs: Self, rhs: QueryItems) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path,
                    queryItems: lhs.queryItems.merging(rhs, uniquingKeysWith: { _, new in new }))
    }

    public static func +(lhs: Self, rhs: [String]) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path + rhs,
                    queryItems: lhs.queryItems)
    }

    public static func +(lhs: Self, rhs: String) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path + [rhs],
                    queryItems: lhs.queryItems)
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
