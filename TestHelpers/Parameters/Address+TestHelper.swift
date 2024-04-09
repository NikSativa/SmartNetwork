import SmartNetwork
import Foundation
import SpryKit

// MARK: - Address + SpryEquatable

extension Address: SpryEquatable {
    public static func testMake(scheme: Scheme? = .https,
                                host: String = "google.com",
                                path: [String] = [],
                                queryItems: QueryItems = [],
                                fragment: String? = nil,
                                shouldAddSlashAfterEndpoint: Bool = false,
                                shouldRemoveSlashesForEmptyScheme: Bool = false) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: path,
                     queryItems: queryItems,
                     fragment: fragment,
                     shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    public static func testMake(scheme: Scheme? = .https,
                                host: String = "google.com",
                                endpoint: String,
                                queryItems: QueryItems = [],
                                fragment: String? = nil,
                                shouldAddSlashAfterEndpoint: Bool = false,
                                shouldRemoveSlashesForEmptyScheme: Bool = false) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: [endpoint],
                     queryItems: queryItems,
                     fragment: fragment,
                     shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    public static func testMake(url: URL) -> Self {
        return try! .init(url: url)
    }

    public static func testMake(string url: String) -> Self {
        return try! .init(string: url)
    }
}
