import Foundation
import SpryKit

@testable import SmartNetwork

extension SmartItem: SpryEquatable {
    public static func testMake(key: String = "", value: T) -> Self {
        return .init(key: key, value: value)
    }
}
