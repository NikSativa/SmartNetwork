import Foundation
import NRequest
import NSpry

extension URLRepresentation: SpryEquatable {
    public static func testMake(scheme: Address.Scheme? = .https,
                                host: String = "",
                                path: [String] = [],
                                queryItems: [String: String] = [:]) -> Self {
        return .init(scheme: scheme,
                     host: host,
                     path: path,
                     queryItems: queryItems)
    }
}
