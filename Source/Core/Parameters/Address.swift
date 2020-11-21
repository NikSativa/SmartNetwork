import Foundation

public typealias QueryItems = [String: String]

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
                queryItems: QueryItems = [:]) {
        let representable = URLRepresentation(scheme: scheme,
                                              host: host,
                                              port: port,
                                              path: path,
                                              queryItems: queryItems)
        self = .address(representable)
    }

    public static func address(scheme: Scheme? = .https,
                               host: String,
                               port: Int? = nil,
                               endpoint: String,
                               queryItems: QueryItems = [:]) -> Address {
        let representable = URLRepresentation(scheme: scheme,
                                              host: host,
                                              port: port,
                                              path: [endpoint].compactMap { $0 },
                                              queryItems: queryItems)
        return .address(representable)
    }

    public static func address(scheme: Scheme? = .https,
                               host: String,
                               port: Int? = nil,
                               path: [String] = [],
                               queryItems: QueryItems = [:]) -> Address {
        return .init(scheme: scheme,
                     host: host,
                     port: port,
                     path: path,
                     queryItems: queryItems)
    }

    public func append(_ pathComponents: [String]) -> Self {
        self + pathComponents
    }

    public func append(_ pathComponent: String) -> Self {
        self + pathComponent
    }

    public func append(_ queryItems: QueryItems) -> Self {
        self + queryItems
    }

    public static func + (lhs: Self, rhs: QueryItems) -> Self {
        let representation: URLRepresentation

        switch lhs {
        case .url(let url):
            representation = .init(url: url)
        case .address(let value):
            representation = value
        }

        return .address(representation + rhs)
    }

    public static func + (lhs: Self, rhs: String) -> Self {
        let representation: URLRepresentation

        switch lhs {
        case .url(let url):
            representation = .init(url: url)
        case .address(let value):
            representation = value
        }

        return .address(representation + rhs)
    }

    public static func + (lhs: Self, rhs: [String]) -> Self {
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

extension Address {
    public func url() throws -> URL {
        switch self {
        case .url(let url):
            return url
        case .address(let url):
            var components = URLComponents()
            components.host = url.host

            switch url.scheme {
            case .none:
                break
            case .http:
                components.scheme = "http"
            case .https:
                components.scheme = "https"
            case .other(let string):
                components.scheme = string
            }

            components.port = url.port

            let path = url.path.flatMap { $0.components(separatedBy: "/") }.filter { !$0.isEmpty }
            if !path.isEmpty {
                components.path = "/" + path.joined(separator: "/")
            }

            if !url.queryItems.isEmpty {
                var result = components.queryItems ?? []

                let keys = url.queryItems.keys
                result = result.filter { !keys.contains($0.name) }

                for (key, value) in url.queryItems {
                    result.append(URLQueryItem(name: key, value: value))
                }
                components.queryItems = result
            }

            if let componentsUrl = components.url {
                return componentsUrl
            }

            throw EncodingError.lackAdress
        }
    }
}
