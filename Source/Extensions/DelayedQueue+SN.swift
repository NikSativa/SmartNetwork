import Foundation
import Threading

internal extension DelayedQueue {
    func unFire(_ block: @escaping () -> Void) {
        let sendable = USendable(block)
        fire {
            sendable.value()
        }
    }
}
