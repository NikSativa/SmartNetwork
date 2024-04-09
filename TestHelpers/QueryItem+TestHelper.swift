import Foundation
import SpryKit

@testable import SmartNetwork

extension QueryItem: SpryEquatable {
    public static func testMake(key: String = "",
                                value: String? = nil) -> Self {
        return .init(key: key,
                     value: value)
    }
}
