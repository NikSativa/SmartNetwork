import Foundation
import Spry

import NRequest

extension Address: SpryEquatable {
    public static func testMake(scheme: String = "",
                                host: String = "",
                                endpoint: String? = nil,
                                queryItems: [String: String] = [:]) -> Address {
        return Address(scheme: scheme,
                       host: host,
                       endpoint: endpoint,
                       queryItems: queryItems)
    }
}
