import Foundation
import NRequest
import NSpry

extension URLRepresentation: SpryEquatable {
    public static func testMake(scheme: Address.Scheme? = .https,
                                host: String = "",
                                path: [String] = [],
                                queryItems: QueryItems = [],
                                fragment: String? = nil) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: path,
                     queryItems: queryItems,
                     fragment: fragment)
    }
}
