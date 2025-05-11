import Foundation

public extension UserInfo {
    /// Tracks the number of attempts made for a given network request.
    ///
    /// This counter is incremented with each retry initiated by the network layer. The initial value is 0.
    /// Used primarily for logging, retry logic, or custom backoff strategies.
    internal(set) var attemptsCount: Int {
        get {
            return self[.smartNetworkRequestAttemptsCount] ?? 0
        }
        set {
            self[.smartNetworkRequestAttemptsCount] = newValue
        }
    }

    /// A unique identifier associated with the request context.
    ///
    /// This value is assigned automatically when a task is created by `SmartRequestManager`.
    /// It can be manually overridden if necessary, though doing so may lead to conflicts in request tracking.
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

    /// Identifies the logical address or route associated with the network task.
    ///
    /// This value is assigned by `SmartRequestManager` and should not be manually modified.
    /// It helps associate the task with its originating request configuration.
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
