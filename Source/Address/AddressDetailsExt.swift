import Foundation

public extension AddressDetails {
    /// add path component
    ///
    ///     a.append("pathComponent")
    ///     https://some.com  ->  https://some.com/pathComponent
    func append(_ pathComponent: String) -> Self {
        return self + pathComponent
    }

    /// add path components `[pathComponent1,pathComponent2]`
    ///
    ///     a.append(["pathComponent1", "pathComponent2"])
    ///
    ///     https://some.com  ->  https://some.com/pathComponent1/pathComponent2
    func append(_ pathComponents: [String]) -> Self {
        return self + pathComponents
    }

    /// add query items
    ///
    ///     a.append(["item1": "1", "item2": 2])
    ///
    ///     https://some.com  ->  https://some.com?item1=1&item2=2
    func append(_ queryItems: QueryItems) -> Self {
        return self + queryItems
    }

    static func +(lhs: Self, rhs: QueryItems) -> Self {
        return .init(scheme: lhs.scheme,
                     host: lhs.host,
                     port: lhs.port,
                     path: lhs.path,
                     queryItems: lhs.queryItems + rhs,
                     fragment: lhs.fragment)
    }

    static func +(lhs: Self, rhs: [String]) -> Self {
        return .init(scheme: lhs.scheme,
                     host: lhs.host,
                     port: lhs.port,
                     path: lhs.path + rhs,
                     queryItems: lhs.queryItems,
                     fragment: lhs.fragment)
    }

    static func +(lhs: Self, rhs: String) -> Self {
        return .init(scheme: lhs.scheme,
                     host: lhs.host,
                     port: lhs.port,
                     path: lhs.path + [rhs],
                     queryItems: lhs.queryItems,
                     fragment: lhs.fragment)
    }
}
