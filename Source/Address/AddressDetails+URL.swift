import Foundation

internal extension AddressDetails {
    func url(shouldAddSlashAfterEndpoint: Bool,
             shouldRemoveSlashesForEmptyScheme: Bool) throws -> URL {
        var components = URLComponents()

        components.scheme = scheme?.toString()
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

        if let fragment = fragment {
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
}
