import Foundation
import NSpry

@testable import NRequest

extension QueryItem: SpryEquatable {
    public static func testMake(key: String = "",
                                value: String? = nil) -> Self {
        return .init(key: key,
                     value: value)
    }
}
