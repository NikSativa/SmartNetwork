import Foundation
import Threading

/// Extension on `DelayedQueue` to support safe deferred execution of closures using `USendable`.
internal extension DelayedQueue {
    /// Schedules the given block to be executed on the delayed queue using a wrapped `USendable`.
    ///
    /// This allows execution of the block in a thread-safe and delayed manner using the existing queue infrastructure.
    ///
    /// - Parameter block: The closure to execute.
    func unFire(_ block: @escaping () -> Void) {
        let sendable = USendable(block)
        fire {
            sendable.value()
        }
    }
}
