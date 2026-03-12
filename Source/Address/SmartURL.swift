import Foundation

/// Encapsulates flexible construction of URLs from various source types.
///
/// `SmartURL` supports initialization from raw strings, `URL`, `URLComponents`, or custom `SmartUrlComponents`.
/// It provides configurable options for formatting, including slash handling and scheme correction,
/// ensuring flexible and safe URL generation for HTTP requests.
public enum SmartURL: Hashable, SmartSendable {
    /// URL represented as a raw string.
    case string(String)
    /// URL represented as native ``URL``.
    case url(URL)
    /// URL represented as native ``URLComponents``.
    case components(URLComponents)
    /// URL represented as ``SmartUrlComponents`` with formatting flags.
    case smartComponents(SmartUrlComponents, shouldAddSlashAfterEndpoint: Bool, shouldRemoveSlashesForEmptyScheme: Bool)

    /// Resolves the url into a `URL`, applying formatting options as needed.
    ///
    /// - Returns: A valid `URL` constructed from the stored source.
    /// - Throws: `RequestEncodingError.brokenURL` or similar if the URL cannot be formed.
    public func url() throws -> URL {
        switch self {
        case let .url(url):
            return url

        case let .string(str):
            return try URL(string: str).unwrap(orThrow: RequestEncodingError.brokenURL)

        case let .components(components):
            return try components.url.unwrap(orThrow: RequestEncodingError.brokenURL)

        case let .smartComponents(components, shouldAddSlashAfterEndpoint, shouldRemoveSlashesForEmptyScheme):
            return try components.url(shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                                      shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
        }
    }
}

public extension SmartURL {
    /// Creates a `.smartComponents` URL source.
    ///
    /// - Parameters:
    ///   - components: URL components value.
    ///   - shouldAddSlashAfterEndpoint: Trailing slash normalization toggle.
    ///   - shouldRemoveSlashesForEmptyScheme: Empty-scheme slash cleanup toggle.
    /// - Returns: ``SmartURL`` in `.smartComponents` form.
    static func components(_ components: SmartUrlComponents,
                           shouldAddSlashAfterEndpoint: Bool = SmartNetworkSettings.shouldAddSlashAfterEndpoint,
                           shouldRemoveSlashesForEmptyScheme: Bool = SmartNetworkSettings.shouldRemoveSlashesForEmptyScheme) -> Self {
        return .smartComponents(components,
                                shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                                shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    /// Convenience initializer for creating an url from a URL.
    ///
    /// - Parameters:
    ///   - urling: A URL source to build the url from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: URL) {
        self = .url(urling)
    }

    /// Convenience initializer for creating an url from a string.
    ///
    /// - Parameters:
    ///   - urling: A String source to build the url from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: String) {
        self = .string(urling)
    }

    /// Convenience initializer for creating an url from URL components.
    ///
    /// - Parameters:
    ///   - urling: A URLComponents source to build the url from.
    ///   - shouldAddSlashAfterEndpoint: Optional formatting behavior.
    ///   - shouldRemoveSlashesForEmptyScheme: Optional formatting behavior.
    init(_ urling: URLComponents) {
        self = .components(urling)
    }

    /// Constructs a full url from individual URL components.
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
        let components = SmartUrlComponents(scheme: scheme,
                                            host: host,
                                            port: port,
                                            path: path,
                                            queryItems: queryItems,
                                            fragment: fragment)
        self = .components(components, shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint, shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    private func internalDescription() -> String {
        if let url = try? url() {
            return url.absoluteString
        }

        switch self {
        case let .url(url):
            return url.description
        case let .string(str):
            return str
        case let .components(components):
            return components.description
        case let .smartComponents(components, shouldAddSlashAfterEndpoint, shouldRemoveSlashesForEmptyScheme):
            return components.description + " shouldAddSlashAfterEndpoint: \(shouldAddSlashAfterEndpoint), shouldRemoveSlashesForEmptyScheme: \(shouldRemoveSlashesForEmptyScheme)"
        }
    }
}

// MARK: - ExpressibleByStringLiteral

/// Allows an url to be created directly from a string literal.
extension SmartURL: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

/// Provides a debug representation of the url.
extension SmartURL: CustomDebugStringConvertible {
    public var debugDescription: String {
        internalDescription()
    }
}

/// Provides a user-friendly string representation of the url.
extension SmartURL: CustomStringConvertible {
    public var description: String {
        internalDescription()
    }
}
