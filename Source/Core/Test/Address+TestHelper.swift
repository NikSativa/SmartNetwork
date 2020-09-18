import Foundation
import Spry

import NRequest

extension Address: SpryEquatable {
    public static func testMake(host: String = "",
                                endpoint: String? = nil,
                                queryItems: [String: String] = [:]) -> Address {
        return Address(host: host,
                       endpoint: endpoint,
                       queryItems: queryItems)
    }
}
