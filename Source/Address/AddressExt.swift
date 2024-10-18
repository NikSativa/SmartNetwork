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

    /// add path component
    ///
    ///     a.append("pathComponent")
    ///     https://some.com  ->  https://some.com/pathComponent
    func append(_ pathComponent: String) throws -> Self {
        return try Address(detailed + pathComponent,
                           shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                           shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    /// add path components `[pathComponent1,pathComponent2]`
    ///
    ///     a.append(["pathComponent1", "pathComponent2"])
    ///
    ///     https://some.com  ->  https://some.com/pathComponent1/pathComponent2
    func append(_ pathComponents: [String]) throws -> Self {
        return try self + pathComponents
    }

    /// add query items
    ///
    ///     a.append(["item1": "1", "item2": 2])
    ///
    ///     https://some.com  ->  https://some.com?item1=1&item2=2
    func append(_ queryItems: QueryItems) throws -> Self {
        return try self + queryItems
    }

    static func +(lhs: Self, rhs: QueryItems) throws -> Self {
        let details = try lhs.detailed + rhs
        return Self(details,
                    shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                    shouldRemoveSlashesForEmptyScheme: lhs.shouldRemoveSlashesForEmptyScheme)
    }

    static func +(lhs: Self, rhs: [String]) throws -> Self {
        let details = try lhs.detailed + rhs
        return Self(details,
                    shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                    shouldRemoveSlashesForEmptyScheme: lhs.shouldRemoveSlashesForEmptyScheme)
    }

    static func +(lhs: Self, rhs: String) throws -> Self {
        let details = try lhs.detailed + rhs
        return Self(details,
                    shouldAddSlashAfterEndpoint: lhs.shouldAddSlashAfterEndpoint,
                    shouldRemoveSlashesForEmptyScheme: lhs.shouldRemoveSlashesForEmptyScheme)
    }
}
