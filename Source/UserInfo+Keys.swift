import Foundation

public extension UserInfo {
    /// The number of attempts made to perform a network request.
    ///
    /// - Note: The value is incremented by 1 each time a network request is made.
    /// - Important: The countdown starts from 0.
    internal(set) var attemptsCount: Int {
        get {
            return self[.smartNetworkRequestAttemptsCount] ?? 0
        }
        set {
            self[.smartNetworkRequestAttemptsCount] = newValue
        }
    }

    /// The unique identifier of the UserInfo. You can overrides the value if needed on your own risk.
    ///
    /// - Important: The value is set when the task is created and available only for tasks created by `SmartRequestManager`.
    var uniqueID: UUID {
        get {
            if let cached: UUID = self[.smartUniqueIDKey] {
                return cached
            }

            let new = UUID()
            self[.smartUniqueIDKey] = new
            return new
        }
        set {
            self[.smartUniqueIDKey] = newValue
        }
    }

    /// The key used to determine which request the task belongs to. You can't override or set the value.
    ///
    /// - Important: The value is set when the task is created and available only for tasks created by `SmartRequestManager`.
    internal(set) var smartRequestAddress: Address? {
        get {
            return self[.smartTaskRequestAddressKey]
        }
        set {
            self[.smartTaskRequestAddressKey] = newValue
        }
    }
}

private extension UserInfoKey {
    static let smartNetworkRequestAttemptsCount: Self = "SmartNetwork.SmartRetrier.AttemptsCount.Key"
    static let smartTaskRequestAddressKey: Self = "SmartNetwork.SmartTask.Request.Address.Key"
    static let smartUniqueIDKey: Self = "SmartNetwork.SmartUniqueID.Key"
}
