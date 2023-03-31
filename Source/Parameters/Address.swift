import Foundation

public struct Address: Equatable {
    public let scheme: Scheme?
    public let host: String
    public let port: Int?
    public let path: [String]
    public let queryItems: QueryItems
    public let fragment: String?

    /// URLComponents is require scheme and generates url like 'https://some.com/end?param=value'
    /// this parameter will add '/' after domain or andpoint 'https://some.com/end/?param=value'
    public let shouldAddSlashAfterEndpoint: Bool

    /// URLComponents is require scheme and generates url like '//some.com/end/?param=value'
    /// this parameter will remove '//' from the begining of new URL
    /// - change this setting on your own risk. I always recommend using the "Address" with the correct "Scheme"
    public let shouldRemoveSlashesForEmptyScheme: Bool

    public init(scheme: Scheme? = .https,
                host: String,
                port: Int? = nil,
                path: [String] = [],
                queryItems: QueryItems = [],
                fragment: String? = nil,
                shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
                shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.queryItems = queryItems
        self.fragment = fragment
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
    }

    public init(url: URL,
                shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
                shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) throws {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!

        self.scheme = Scheme(components.scheme)
        self.host = try components.host.unwrap(orThrow: RequestEncodingError.brokenHost)
        self.port = components.port
        self.path = components.path.components(separatedBy: "/")
        self.fragment = components.fragment

        let items: [QueryItems.Element] = (components.queryItems ?? []).map {
            return .init(key: $0.name, value: $0.value)
        }
        self.queryItems = .init(items)

        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
    }

    public init(string: String,
                shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
                shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) throws {
        let url = try URL(string: string).unwrap(orThrow: RequestEncodingError.brokenURL)
        try self.init(url: url,
                      shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                      shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }
}

private extension Scheme {
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

public extension Address {
    func url() throws -> URL {
        var components = URLComponents()

        switch scheme {
        case .none:
            components.scheme = nil
        case .http:
            components.scheme = "http"
        case .https:
            components.scheme = "https"
        case .other(let string):
            components.scheme = string.isEmpty ? nil : string
        }

        components.host = host
        components.port = port

        let path = path.flatMap { $0.components(separatedBy: "/") }.filter { !$0.isEmpty }
        if !path.isEmpty {
            components.path = "/" + path.joined(separator: "/")
        }

        if shouldAddSlashAfterEndpoint {
            components.path += "/"
        }

        if !queryItems.isEmpty {
            var result = components.queryItems ?? []
            for item in queryItems {
                result.append(URLQueryItem(name: item.key, value: item.value))
            }
            components.queryItems = result
        }

        if let fragment {
            components.fragment = fragment
        }

        let componentsUrl: URL?
        let newHost: String?
        if shouldRemoveSlashesForEmptyScheme,
           components.scheme == nil,
           let componentsString = components.string,
           componentsString.hasPrefix("//") {
            let strUrl = String(componentsString.dropFirst(2))
            componentsUrl = URL(string: strUrl)
            newHost = host
        } else {
            componentsUrl = components.url
            newHost = componentsUrl?.host
        }

        if let componentsUrl,
           newHost == host {
            return componentsUrl
        }

        throw RequestEncodingError.brokenAddress
    }

    /// add path component
    ///
    ///     a.append("pathComponent")
    ///     https://some.com  ->  https://some.com/pathComponent
    func append(_ pathComponent: String) -> Self {
        return self + pathComponent
    }

    /// add path components `[pathComponent1,pathComponent2]`
    ///
    ///     a.append(["pathComponent1", "pathComponent2"])
    ///
    ///     https://some.com  ->  https://some.com/pathComponent1/pathComponent2
    func append(_ pathComponents: [String]) -> Self {
        return self + pathComponents
    }

    /// add query items
    ///
    ///     a.append(["item1": "1", "item2": 2])
    ///
    ///     https://some.com  ->  https://some.com?item1=1&item2=2
    func append(_ queryItems: QueryItems) -> Self {
        return self + queryItems
    }

    static func +(lhs: Self, rhs: QueryItems) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path,
                    queryItems: lhs.queryItems + rhs,
                    fragment: lhs.fragment,
                    shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                    shouldRemoveSlashesForEmptyScheme: lhs.shouldAddSlashAfterEndpoint)
    }

    static func +(lhs: Self, rhs: [String]) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path + rhs,
                    queryItems: lhs.queryItems,
                    fragment: lhs.fragment,
                    shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                    shouldRemoveSlashesForEmptyScheme: lhs.shouldAddSlashAfterEndpoint)
    }

    static func +(lhs: Self, rhs: String) -> Self {
        return Self(scheme: lhs.scheme,
                    host: lhs.host,
                    port: lhs.port,
                    path: lhs.path + [rhs],
                    queryItems: lhs.queryItems,
                    fragment: lhs.fragment,
                    shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                    shouldRemoveSlashesForEmptyScheme: lhs.shouldAddSlashAfterEndpoint)
    }
}
