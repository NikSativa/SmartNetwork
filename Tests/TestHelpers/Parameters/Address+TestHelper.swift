import Foundation
import SmartNetwork
import SpryKit

// MARK: - Address + SpryEquatable

public extension Address {
    static func testMake(scheme: Scheme? = .https,
                         host: String = "www.apple.com",
                         path: [String] = [],
                         queryItems: QueryItems = [],
                         fragment: String? = nil,
                         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
                         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: path,
                     queryItems: queryItems,
                     fragment: fragment,
                     shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    static func testMake(scheme: Scheme? = .https,
                         host: String = "www.apple.com",
                         endpoint: String,
                         queryItems: QueryItems = [],
                         fragment: String? = nil,
                         shouldAddSlashAfterEndpoint: Bool = RequestSettings.shouldAddSlashAfterEndpoint,
                         shouldRemoveSlashesForEmptyScheme: Bool = RequestSettings.shouldRemoveSlashesForEmptyScheme) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: [endpoint],
                     queryItems: queryItems,
                     fragment: fragment,
                     shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                     shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    }

    static func testMake(url: URL) -> Self {
        return .init(url)
    }

    static func testMake(string url: String) -> Self {
        return .init(url)
    }
}
