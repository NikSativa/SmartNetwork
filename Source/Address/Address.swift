import Foundation

/// Encapsulates flexible construction of URLs from various source types.
///
/// `Address` supports initialization from raw strings, `URL`, `URLComponents`, or custom `AddressDetails`.
/// It provides configurable options for formatting, including slash handling and scheme correction,
/// ensuring flexible and safe URL generation for HTTP requests.
public struct Address: Hashable, SmartSendable {
    public enum Source: Hashable, SmartSendable {
        case string(String)
        case url(URL)
        case components(URLComponents)
        case details(AddressDetails)
    }

    /// The origin from which the address is constructed (e.g., string, URL, components, or custom details).
    public let source: Source

    /// Appends a trailing slash after the final path component, if not already present.
    ///
    /// Useful when `URLComponents` omits trailing slashes and one is required by the endpoint.
    public let shouldAddSlashAfterEndpoint: Bool

    /// Removes leading slashes when the URL scheme is empty (e.g., `//host/path` → `host/path`).
    ///
    /// Use with caution. It is recommended to define a scheme explicitly when constructing URLs.
    public let shouldRemoveSlashesForEmptyScheme: Bool

    /// Initializes an address with a given source and formatting options.
    ///
    /// - Parameters:
    ///   - urling: The source from which to construct the address.
    ///   - shouldAddSlashAfterEndpoint: Whether to add a trailing slash at the end of the path.
    ///   - shouldRemoveSlashesForEmptyScheme: Whether to strip leading slashes when scheme is absent.
    init(_ urling: Source,
         shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = urling
    }

    /// Resolves the address into a `URL`, applying formatting options as needed.
    ///
    /// - Returns: A valid `URL` constructed from the stored source.
    /// - Throws: `RequestEncodingError.brokenURL` or similar if the URL cannot be formed.
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
    /// Convenience initializer for creating an address from a URL.
    ///
    /// - Parameters:
    ///   - urling: A URL source to build the address from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: URL,
         shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .url(urling)
    }

    /// Convenience initializer for creating an address from a string.
    ///
    /// - Parameters:
    ///   - urling: A String source to build the address from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: String,
         shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .string(urling)
    }

    /// Convenience initializer for creating an address from URL components.
    ///
    /// - Parameters:
    ///   - urling: A URLComponents source to build the address from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: URLComponents,
         shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .components(urling)
    }

    /// Convenience initializer for creating an address from address details.
    ///
    /// - Parameters:
    ///   - urling: An AddressDetails source to build the address from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: AddressDetails,
         shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) {
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
        self.shouldRemoveSlashesForEmptyScheme = shouldRemoveSlashesForEmptyScheme
        self.source = .details(urling)
    }

    /// Constructs a full address from individual URL components.
    ///
    /// - Parameters:
    ///   - scheme: The scheme (`http`, `https`, etc.) to use.
    ///   - host: The host name.
    ///   - port: An optional port number.
    ///   - path: An array of path components.
    ///   - queryItems: A dictionary of query parameters.
    ///   - fragment: An optional fragment string.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(scheme: Scheme? = .https,
         host: String,
         port: Int? = nil,
         path: [String] = [],
         queryItems: QueryItems = [:],
         fragment: String? = nil,
         shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
         shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) {
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

// Enables literal initialization of `Address` from string values.

/// Allows an address to be created directly from a string literal.
extension Address: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - CustomDebugStringConvertible

// Provides enhanced debugging output for `Address`.

/// Provides a debug representation of the address.
extension Address: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let url = try? url() {
            return url.absoluteString
        }

        return source.debugDescription
    }
}

// MARK: - CustomStringConvertible

// Provides user-facing string output for `Address`.

/// Provides a user-friendly string representation of the address.
extension Address: CustomStringConvertible {
    public var description: String {
        if let url = try? url() {
            return url.absoluteString
        }

        return source.description
    }
}

// MARK: - Address.Source + CustomDebugStringConvertible

// Enables debug-friendly output for address sources.

/// Provides a debug representation of the address source.
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

// Enables readable output for address sources.

/// Provides a user-friendly string representation of the address source.
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
