import Foundation
import SmartNetwork
import SpryKit

extension SmartItem: SpryEquatable {
    public static func testMake(key: String = "", value: T) -> Self {
        return .init(key: key, value: value)
    }
}
