import Foundation

public struct Address: Equatable {
    public let address: String
    public let endpoint: String?
    public let queryItems: [String: String]

    public init(address: String, endpoint: String? = nil, queryItems: [String: String] = [:]) {
        self.address = address
        self.endpoint = endpoint
        self.queryItems = queryItems
    }
}

extension Address {
    func url() throws -> URL {
        guard var url = URL(string: address) else {
            throw EncodingError.lackAdress
        }

        if let endpoint = endpoint {
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
