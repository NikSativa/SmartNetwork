import Foundation

public extension AddressDetails {
    /// Appends a single path component to the address.
    ///
    /// Example:
    /// ```swift
    /// let updated = a.append("pathComponent")
    /// // https://some.com → https://some.com/pathComponent
    /// ```
    /// - Parameter pathComponent: A single path segment to append.
    /// - Returns: A new `AddressDetails` instance with the component appended.
    func append(_ pathComponent: String) -> Self {
        return self + pathComponent
    }

    /// Appends multiple path components to the address.
    ///
    /// Example:
    /// ```swift
    /// let updated = a.append(["path1", "path2"])
    /// // https://some.com → https://some.com/path1/path2
    /// ```
    /// - Parameter pathComponents: An array of path segments to append.
    /// - Returns: A new `AddressDetails` instance with the components appended.
    func append(_ pathComponents: [String]) -> Self {
        return self + pathComponents
    }

    /// Appends query items to the address.
    ///
    /// Example:
    /// ```swift
    /// let updated = a.append(["key": "value"])
    /// // https://some.com → https://some.com?key=value
    /// ```
    /// - Parameter queryItems: A dictionary of query parameters to append.
    /// - Returns: A new `AddressDetails` instance with the query items merged.
    func append(_ queryItems: QueryItems) -> Self {
        return self + queryItems
    }

    /// Returns a new `AddressDetails` instance with the given query items merged into the existing ones.
    static func +(lhs: Self, rhs: QueryItems) -> Self {
        return .init(scheme: lhs.scheme,
                     host: lhs.host,
                     port: lhs.port,
                     path: lhs.path,
                     queryItems: lhs.queryItems + rhs,
                     fragment: lhs.fragment)
    }

    /// Returns a new `AddressDetails` instance with the given path components appended to the current path.
    static func +(lhs: Self, rhs: [String]) -> Self {
        return .init(scheme: lhs.scheme,
                     host: lhs.host,
                     port: lhs.port,
                     path: lhs.path + rhs,
                     queryItems: lhs.queryItems,
                     fragment: lhs.fragment)
    }

    /// Returns a new `AddressDetails` instance with the given path component appended to the current path.
    static func +(lhs: Self, rhs: String) -> Self {
        return .init(scheme: lhs.scheme,
                     host: lhs.host,
                     port: lhs.port,
                     path: lhs.path + [rhs],
                     queryItems: lhs.queryItems,
                     fragment: lhs.fragment)
    }
}
