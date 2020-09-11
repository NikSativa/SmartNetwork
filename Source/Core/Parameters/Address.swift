import Foundation

public enum Address: Equatable {
    case url(URL)
    case address(host: String, endpoint: String?, queryItems: [String: String])

    public init(host: String,
                endpoint: String? = nil,
                queryItems: [String: String] = [:]) {
        self = .address(host: host,
                        endpoint: endpoint,
                        queryItems: queryItems)
    }
}

extension Address {
    func url() throws -> URL {
        switch self {
        case .url(let url):
            return url

        case let .address(host, endpoint, queryItems):
            guard var url = URL(string: host) else {
                throw EncodingError.lackAdress
            }

            if let endpoint = endpoint, !endpoint.isEmpty {
                url.appendPathComponent(endpoint)
            }

            if queryItems.isEmpty {
                return url
            }

            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var result = components?.queryItems ?? []

            let keys = queryItems.keys
            result = result.filter({ !keys.contains($0.name) })

            for (key, value) in queryItems {
                result.append(URLQueryItem(name: key, value: value))
            }
            components?.queryItems = result

            if let componentsUrl = components?.url {
                url = componentsUrl
            }
            
            return url
        }
    }
}
