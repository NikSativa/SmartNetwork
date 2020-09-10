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

            var query = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var result = query?.queryItems ?? []
            for (key, value) in queryItems {
                result.append(URLQueryItem(name: key, value: value))
            }
            query?.queryItems = result

            return query?.url ?? url
        }
    }
}
