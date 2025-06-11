import Foundation

/// Represents the components of a URL such as scheme, host, port, path, query items, and fragment.
///
/// `AddressDetails` provides a structured way to represent and manipulate URLs in a composable and testable form,
/// useful for constructing requests or parsing existing URLs.
public struct AddressDetails: Hashable, SmartSendable {
    /// The URL scheme (e.g., http, https, or custom).
    public let scheme: Scheme?
    /// The host portion of the URL (e.g., "example.com").
    public let host: String
    /// The port number, if specified.
    public let port: Int?
    /// An array of path components that form the URL path.
    public let path: [String]
    /// A dictionary of query items attached to the URL.
    public let queryItems: QueryItems
    /// The fragment identifier, if present.
    public let fragment: String?

    public init(scheme: Scheme? = .https,
                host: String,
                port: Int? = nil,
                path: [String] = [],
                queryItems: QueryItems = [:],
                fragment: String? = nil) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.queryItems = queryItems
        self.fragment = fragment
    }
}

public extension AddressDetails {
    /// Initializes `AddressDetails` from a `URLComponents` instance.
    ///
    /// - Parameter components: A parsed URL components object.
    /// - Throws: `RequestEncodingError.brokenHost` if the host is missing.
    init(components: URLComponents) throws {
        self.scheme = components.scheme.sdk
        self.host = try components.host.unwrap(orThrow: RequestEncodingError.brokenHost)
        self.port = components.port
        self.path = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
        self.fragment = components.fragment

        let items: [SmartItem<String?>] = (components.queryItems ?? []).map {
            return .init(key: $0.name, value: $0.value)
        }
        self.queryItems = .init(items)
    }

    /// Initializes `AddressDetails` from a `URL`.
    ///
    /// - Parameter url: A complete URL to parse.
    /// - Throws: `RequestEncodingError.brokenURL` if URL components cannot be resolved.
    init(url: URL) throws {
        let components = try URLComponents(url: url, resolvingAgainstBaseURL: true).unwrap(orThrow: RequestEncodingError.brokenURL)
        try self.init(components: components)
    }

    /// Initializes `AddressDetails` from a URL string.
    ///
    /// - Parameter string: The string representation of a URL.
    /// - Throws: `RequestEncodingError.brokenURL` if the string is invalid.
    init(string: String) throws {
        let url = try URL(string: string).unwrap(orThrow: RequestEncodingError.brokenURL)
        try self.init(url: url)
    }
}

// MARK: - CustomDebugStringConvertible

extension AddressDetails: CustomDebugStringConvertible {
    /// A debug-friendly string representation of the address.
    public var debugDescription: String {
        return makeDescription()
    }
}

// MARK: - CustomStringConvertible

extension AddressDetails: CustomStringConvertible {
    /// A user-friendly string representation of the address.
    public var description: String {
        return makeDescription()
    }
}

private extension AddressDetails {
    /// Constructs a readable string representation from the address components.
    ///
    /// Includes scheme, host, port, path, query, and fragment if available.
    private func makeDescription() -> String {
        let text: [String?] = [
            scheme?.toString().map { "\($0)://" },
            host,
            port.map { ":\($0)" },
            path.isEmpty ? nil : "/",
            path.joined(separator: "/"),
            queryItems.isEmpty ? nil : "?",
            queryItems.mapToDescription()
                .map {
                    if let value = $0.value {
                        return "\($0.key)=\(value)"
                    }
                    return $0.key
                }
                .joined(separator: "&"),
            fragment.map { "#\($0)" }
        ]

        return text.filterNils().joined()
    }
}

private extension String? {
    /// Maps a scheme string (e.g., "http") to a `Scheme` enum case.
    ///
    /// Falls back to `.other(...)` for custom schemes.
    var sdk: Scheme? {
        guard let self, !self.isEmpty else {
            return nil
        }

        if self.hasPrefix("https") {
            return .https
        } else if self.hasPrefix("http") {
            return .http
        } else {
            return .other(self)
        }
    }
}
