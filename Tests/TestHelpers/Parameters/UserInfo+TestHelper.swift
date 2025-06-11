import Foundation
import SmartNetwork
import SpryKit

// MARK: - UserInfo + SpryEquatable

extension UserInfo: SpryEquatable {
    public static func testMake(storage: [UserInfoKey: Any] = [:]) -> Self {
        return .init(storage)
    }
}

// MARK: - UserInfo + Equatable

extension UserInfo: Equatable {
    public static func ==(lhs: UserInfo, rhs: UserInfo) -> Bool {
        guard JSONSerialization.isValidJSONObject(lhs.values) else {
            assertionFailure("can't camopare")
            return false
        }
        guard JSONSerialization.isValidJSONObject(rhs.values) else {
            assertionFailure("can't camopare")
            return false
        }

        let a = try? JSONSerialization.data(withJSONObject: lhs.values, options: [])
        let b = try? JSONSerialization.data(withJSONObject: rhs.values, options: [])
        return a != nil && a == b
    }
}
