#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import SpryKit
import Threading

@Spryable
final class FakeSmartTask: SmartTasking {
    @SpryableVar
    var userInfo: UserInfo

    @SpryableFunc
    func detach() -> DetachedTask

    @SpryableFunc
    func start()

    @SpryableFunc
    func deferredStart(in queue: Queueable) -> FakeSmartTask

    @SpryableFunc
    func deferredStart() -> FakeSmartTask

    @SpryableFunc
    func cancel()
}
#endif
