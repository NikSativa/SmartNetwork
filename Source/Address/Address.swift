import Foundation

/// The struct Address is designed to encapsulate URL-related information and
/// provide flexibility in constructing URLs based on different sources and configurations.
public struct Address: Hashable {
    public enum Source: Hashable {
        case string(String)
        case url(URL)
        case components(URLComponents)
        case details(AddressDetails)
    }

    public let source: Source

    /// URLComponents is require scheme and generates url like 'https://some.com/end?param=value'
    /// this parameter will add '/' after domain or andpoint 'https://some.com/end/?param=value'
    public let shouldAddSlashAfterEndpoint: Bool

    /// URLComponents is require scheme and generates url like '//some.com/end/?param=value'
    /// this parameter will remove '//' from the begining of new URL
    /// - change this setting on your own risk. I always recommend using the "Address" with the correct "Scheme"
    public let shouldRemoveSlashesForEmptyScheme: Bool

    init(_ urling: Source,
         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = urling
    }

    public func url() throws -> URL {
        switch source {
        case .url(let url):
            return url
        case .string(let str):
            return try URL(string: str).unwrap(orThrow: RequestEncodingError.brokenURL)
        case .components(let components):
            return try components.url.unwrap(orThrow: RequestEncodingError.brokenURL)
        case .details(let details):
            return try details.url(shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                                   shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
        }
    }
}

public extension Address {
    init(_ urling: URL,
         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .url(urling)
    }

    init(_ urling: String,
         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .string(urling)
    }

    init(_ urling: URLComponents,
         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .components(urling)
    }

    init(_ urling: AddressDetails,
         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .details(urling)
    }

    init(scheme: Scheme? = .https,
         host: String,
         port: Int? = nil,
         path: [String] = [],
         queryItems: QueryItems = [:],
         fragment: String? = nil,
         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme

        let details = AddressDetails(scheme: scheme,
                                     host: host,
                                     port: port,
                                     path: path,
                                     queryItems: queryItems,
                                     fragment: fragment)
        self.source = .details(details)
    }
}

// MARK: - ExpressibleByStringLiteral

extension Address: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - CustomDebugStringConvertible

extension Address: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let url = try? url() {
            return url.absoluteString
        }

        return source.debugDescription
    }
}

// MARK: - CustomStringConvertible

extension Address: CustomStringConvertible {
    public var description: String {
        if let url = try? url() {
            return url.absoluteString
        }

        return source.description
    }
}

// MARK: - Address.Source + CustomDebugStringConvertible

extension Address.Source: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .url(let url):
            return url.debugDescription
        case .string(let str):
            return str
        case .components(let components):
            return components.debugDescription
        case .details(let details):
            return details.debugDescription
        }
    }
}

// MARK: - Address.Source + CustomStringConvertible

extension Address.Source: CustomStringConvertible {
    public var description: String {
        switch self {
        case .url(let url):
            return url.description
        case .string(let str):
            return str
        case .components(let components):
            return components.description
        case .details(let details):
            return details.description
        }
    }
}

#if swift(>=6.0)
extension Address: Sendable {}
extension Address.Source: Sendable {}
#endif
