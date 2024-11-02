#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import SpryKit
import Threading

@Spryable
final class FakeDetachedTask: DetachedTask {
    @SpryableFunc
    func start()

    @SpryableFunc
    func deferredStart(in queue: any Threading.Queueable) -> Self

    @SpryableFunc
    func deferredStart() -> Self

    @SpryableFunc
    func cancel()
}
#endif
