import Foundation

public struct Address: Equatable {
    public let address: String
    public let endpoint: String?
    public let components: [String: String]

    public init(address: String, endpoint: String? = nil, components: [String: String] = [:]) {
        self.address = address
        self.endpoint = endpoint
        self.components = components
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

        if components.isEmpty {
            return url
        }

        var query = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var result = query?.queryItems ?? []
        for (key, value) in components {
            result.append(URLQueryItem(name: key, value: value))
        }
        query?.queryItems = result

        return query?.url ?? url
    }
}
