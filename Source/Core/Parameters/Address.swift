import Foundation

public typealias QueryItems = [String: String]

public struct Address: Equatable {
    /// https
    let scheme: String?
    /// google.com
    let host: String
    /// /search/
    let endpoint: String?
    /// text=input
    let queryItems: QueryItems

    public init(scheme: String? = nil,
                host: String,
                endpoint: String? = nil,
                queryItems: QueryItems = [:]) {
        self.scheme = scheme
        self.host = host
        self.endpoint = endpoint
        self.queryItems = queryItems
    }

    public static func url(_ url: URL) -> Address {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let scheme = components?.scheme {
            let host = components?.host ?? ""
            let endpoint = components?.path
            let queryItems: [String: String] = (components?.queryItems ?? []).reduce(into: [:], { $0[$1.name] = $1.value })
            return .init(scheme: scheme,
                         host: host,
                         endpoint: endpoint,
                         queryItems: queryItems)
        } else {
            let host = components?.host ?? components?.path ?? ""
            let queryItems: [String: String] = (components?.queryItems ?? []).reduce(into: [:], { $0[$1.name] = $1.value })
            return .init(host: host,
                         queryItems: queryItems)
        }
    }

    public static func address(scheme: String? = nil,
                               host: String,
                               endpoint: String? = nil,
                               queryItems: QueryItems = [:]) -> Address {
        return Address(scheme: scheme,
                       host: host,
                       endpoint: endpoint,
                       queryItems: queryItems)
    }
}

extension Address {
    func url() throws -> URL {
        guard var components = URLComponents(string: host) else {
            throw EncodingError.lackAdress
        }

        if let scheme = scheme {
            components.scheme = scheme
        }

        if !queryItems.isEmpty {
            var result = components.queryItems ?? []

            let keys = queryItems.keys
            result = result.filter { !keys.contains($0.name) }

            for (key, value) in queryItems {
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
