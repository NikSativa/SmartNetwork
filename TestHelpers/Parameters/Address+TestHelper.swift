import Foundation
import Spry

import NRequest

extension Address: SpryEquatable {
    public static func testMake(url: URL) -> Self {
        return .url(url)
    }

    public static func testMake(scheme: Scheme? = .https,
                                host: String = "",
                                path: [String] = [],
                                queryItems: [String: String] = [:]) -> Self {
        return .address(scheme: scheme,
                        host: host,
                        path: path,
                        queryItems: queryItems)
    }
}

extension URLRepresentation: SpryEquatable {
    public static func testMake(scheme: Scheme? = .https,
                                host: String = "",
                                path: [String] = [],
                                queryItems: [String: String] = [:]) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: path,
                     queryItems: queryItems)
    }
}

extension Address.Scheme: SpryEquatable {
}
