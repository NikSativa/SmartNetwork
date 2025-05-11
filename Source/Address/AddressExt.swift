import Foundation

public extension Address {
    private var detailed: AddressDetails {
        get throws {
            switch source {
            case .details(let details):
                return details
            case .string(let str):
                return try .init(string: str)
            case .url(let url):
                return try .init(url: url)
            case .components(let components):
                return try components.url.map(AddressDetails.init).unwrap(orThrow: RequestEncodingError.brokenURL)
            }
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
    /// - Returns: A new `Address` instance with the appended path.
    /// - Throws: `RequestEncodingError` if the URL cannot be formed.
    func append(_ pathComponent: String) throws -> Self {
        return try Address(detailed + pathComponent,
                           shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                           shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    /// Appends multiple path components to the URL.
    ///
    /// Example:
    /// ```swift
    /// a.append(["pathComponent1", "pathComponent2"])
    /// // https://some.com -> https://some.com/pathComponent1/pathComponent2
    /// ```
    /// - Parameter pathComponents: The path segments to add.
    /// - Returns: A new `Address` instance with all components appended.
    /// - Throws: `RequestEncodingError` if the URL cannot be formed.
    func append(_ pathComponents: [String]) throws -> Self {
        return try self + pathComponents
    }

    /// Appends query items to the URL.
    ///
    /// Example:
    /// ```swift
    /// a.append(["item1": "1", "item2": 2])
    /// // https://some.com -> https://some.com?item1=1&item2=2
    /// ```
    /// - Parameter queryItems: The query parameters to append.
    /// - Returns: A new `Address` instance with appended query items.
    /// - Throws: `RequestEncodingError` if the URL cannot be formed.
    func append(_ queryItems: QueryItems) throws -> Self {
        return try self + queryItems
    }

    /// Combines the `Address` with `QueryItems` and returns a new `Address`.
    ///
    /// - Throws: `RequestEncodingError` if the resulting URL is invalid.
    static func +(lhs: Self, rhs: QueryItems) throws -> Self {
        let details = try lhs.detailed + rhs
        return .init(details,
                     shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: lhs.shouldRemoveSlashesForEmptyScheme)
    }

    /// Combines the `Address` with `[String]` and returns a new `Address`.
    ///
    /// - Throws: `RequestEncodingError` if the resulting URL is invalid.
    static func +(lhs: Self, rhs: [String]) throws -> Self {
        let details = try lhs.detailed + rhs
        return .init(details,
                     shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: lhs.shouldRemoveSlashesForEmptyScheme)
    }

    /// Combines the `Address` with `String` and returns a new `Address`.
    ///
    /// - Throws: `RequestEncodingError` if the resulting URL is invalid.
    static func +(lhs: Self, rhs: String) throws -> Self {
        let details = try lhs.detailed + rhs
        return .init(details,
                     shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: lhs.shouldRemoveSlashesForEmptyScheme)
    }
}
