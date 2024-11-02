import Foundation
import Threading

internal extension DelayedQueue {
    func unFire(_ block: @escaping () -> Void) {
        let sendable = UnSendable(block)
        fire {
            sendable.value()
        }
    }
}
