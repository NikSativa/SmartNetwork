import Foundation
import NRequest
import NSpry

// MARK: - Address + SpryEquatable

extension Address: SpryEquatable {
    public static func testMake(url: URL) -> Self {
        return .url(url)
    }

    public static func testMake(string url: String) -> Self {
        return .url(URL(string: url).unsafelyUnwrapped)
    }

    public static func testMake(scheme: Scheme? = .https,
                                host: String = "google.com",
                                path: [String] = [],
                                queryItems: [String: String] = [:]) -> Self {
        return .address(scheme: scheme,
                        host: host,
                        path: path,
                        queryItems: queryItems)
    }
}

extension Address.Scheme: SpryEquatable {}
