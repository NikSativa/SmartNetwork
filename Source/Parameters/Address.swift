import Foundation

public enum Address: Equatable {
    public enum Scheme: Equatable {
        case http
        case https
        case other(String)
    }

    case url(URL)
    case address(URLRepresentation)

    public init(scheme: Scheme? = .https,
                host: String,
                port: Int? = nil,
                path: [String] = [],
                queryItems: QueryItems = [],
                fragment: String? = nil) {
        let representable = URLRepresentation(scheme: scheme,
                                              host: host,
                                              port: port,
                                              path: path,
                                              queryItems: queryItems,
                                              fragment: fragment)
        self = .address(representable)
    }

    public static func address(scheme: Scheme? = .https,
                               host: String,
                               port: Int? = nil,
                               endpoint: String,
                               queryItems: QueryItems = [],
                               fragment: String? = nil) -> Address {
        let representable = URLRepresentation(scheme: scheme,
                                              host: host,
                                              port: port,
                                              path: [endpoint].compactMap { $0 },
                                              queryItems: queryItems,
                                              fragment: fragment)
        return .address(representable)
    }

    public static func address(scheme: Scheme? = .https,
                               host: String,
                               port: Int? = nil,
                               path: [String] = [],
                               queryItems: QueryItems = [],
                               fragment: String? = nil) -> Address {
        return .init(scheme: scheme,
                     host: host,
                     port: port,
                     path: path,
                     queryItems: queryItems,
                     fragment: fragment)
    }

    public func append(_ pathComponents: [String]) -> Self {
        return self + pathComponents
    }

    public func append(_ pathComponent: String) -> Self {
        return self + pathComponent
    }

    public func append(_ queryItems: QueryItems) -> Self {
        return self + queryItems
    }

    public static func +(lhs: Self, rhs: QueryItems) -> Self {
        let representation: URLRepresentation

        switch lhs {
        case .url(let url):
            representation = .init(url: url)
        case .address(let value):
            representation = value
        }

        return .address(representation + rhs)
    }

    public static func +(lhs: Self, rhs: String) -> Self {
        let representation: URLRepresentation

        switch lhs {
        case .url(let url):
            representation = .init(url: url)
        case .address(let value):
            representation = value
        }

        return .address(representation + rhs)
    }

    public static func +(lhs: Self, rhs: [String]) -> Self {
        let representation: URLRepresentation

        switch lhs {
        case .url(let url):
            representation = .init(url: url)
        case .address(let value):
            representation = value
        }

        return .address(representation + rhs)
    }
}

public extension Address {
    func url(shouldAddSlashAfterEndpoint: Bool = Parameters.shouldAddSlashAfterEndpoint,
             shouldRemoveSlashesBeforeEmptyScheme: Bool = Parameters.shouldRemoveSlashesBeforeEmptyScheme) throws -> URL {
        switch self {
        case .url(let url):
            return url
        case .address(let url):
            var components = URLComponents()

            switch url.scheme {
            case .none:
                components.scheme = nil
            case .http:
                components.scheme = "http"
            case .https:
                components.scheme = "https"
            case .other(let string):
                components.scheme = string
            }

            components.host = url.host
            components.port = url.port

            let path = url.path.flatMap { $0.components(separatedBy: "/") }.filter { !$0.isEmpty }
            if !path.isEmpty {
                components.path = "/" + path.joined(separator: "/")
            }

            if shouldAddSlashAfterEndpoint {
                components.path += "/"
            }

            if !url.queryItems.isEmpty {
                var result = components.queryItems ?? []
                for item in url.queryItems {
                    result.append(URLQueryItem(name: item.key, value: item.value))
                }
                components.queryItems = result
            }

            if let fragment = url.fragment {
                components.fragment = fragment
            }

            let componentsUrl: URL?
            let host: String?
            if shouldRemoveSlashesBeforeEmptyScheme,
               components.scheme == nil,
               let componentsString = components.string,
               componentsString.hasPrefix("//") {
                let strUrl = String(componentsString.dropFirst(2))
                componentsUrl = URL(string: strUrl)
                host = url.host
            } else {
                componentsUrl = components.url
                host = componentsUrl?.host
            }

            if let componentsUrl,
               host == url.host {
                return componentsUrl
            }

            throw RequestEncodingError.lackAdress
        }
    }
}
