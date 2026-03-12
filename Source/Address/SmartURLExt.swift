import Foundation

public extension SmartURL {
    private func modify(_ modifier: (SmartUrlComponents) throws -> SmartUrlComponents) throws -> Self {
        switch self {
        case let .smartComponents(components, shouldAddSlashAfterEndpoint, shouldRemoveSlashesForEmptyScheme):
            return try .smartComponents(modifier(components), shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint, shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)

        case let .string(str):
            let components: SmartUrlComponents = try .init(string: str)
            return try .components(modifier(components))

        case let .url(url):
            let components: SmartUrlComponents = try .init(url: url)
            return try .components(modifier(components))

        case let .components(components):
            let components: SmartUrlComponents = try components.url.map(SmartUrlComponents.init).unwrap(orThrow: RequestEncodingError.brokenURL)
            return try .components(modifier(components))
        }
    }

    /// Appends a single path component to the URL.
    ///
    /// Example:
    /// ```swift
    /// a.append("pathComponent")
    /// // https://some.com -> https://some.com/pathComponent
    /// ```
    /// - Parameter pathComponent: The path segment to add.
    /// - Returns: A new `SmartURL` instance with the appended path.
    /// - Throws: `RequestEncodingError` if the URL cannot be formed.
    func append(_ pathComponent: String) throws -> Self {
        return try modify {
            $0 + pathComponent
        }
    }

    /// Appends multiple path components to the URL.
    ///
    /// Example:
    /// ```swift
    /// a.append(["pathComponent1", "pathComponent2"])
    /// // https://some.com -> https://some.com/pathComponent1/pathComponent2
    /// ```
    /// - Parameter pathComponents: The path segments to add.
    /// - Returns: A new `SmartURL` instance with all components appended.
    /// - Throws: `RequestEncodingError` if the URL cannot be formed.
    func append(_ pathComponents: [String]) throws -> Self {
        return try modify {
            $0 + pathComponents
        }
    }

    /// Appends query items to the URL.
    ///
    /// Example:
    /// ```swift
    /// a.append(["item1": "1", "item2": 2])
    /// // https://some.com -> https://some.com?item1=1&item2=2
    /// ```
    /// - Parameter queryItems: The query parameters to append.
    /// - Returns: A new `SmartURL` instance with appended query items.
    /// - Throws: `RequestEncodingError` if the URL cannot be formed.
    func append(_ queryItems: QueryItems) throws -> Self {
        return try modify {
            $0 + queryItems
        }
    }

    /// Combines the `SmartURL` with `QueryItems` and returns a new `SmartURL`.
    ///
    /// - Throws: `RequestEncodingError` if the resulting URL is invalid.
    static func +(lhs: Self, rhs: QueryItems) throws -> Self {
        return try lhs.append(rhs)
    }

    /// Combines the `SmartURL` with `[String]` and returns a new `SmartURL`.
    ///
    /// - Throws: `RequestEncodingError` if the resulting URL is invalid.
    static func +(lhs: Self, rhs: [String]) throws -> Self {
        return try lhs.append(rhs)
    }

    /// Combines the `SmartURL` with `String` and returns a new `SmartURL`.
    ///
    /// - Throws: `RequestEncodingError` if the resulting URL is invalid.
    static func +(lhs: Self, rhs: String) throws -> Self {
        return try lhs.append(rhs)
    }
}
