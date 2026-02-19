#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

@Spryable
final class FakeRequestManager: RequestManager, @unchecked Sendable {
    @SpryableFunc
    func request(url: SmartURL, parameters: Parameters, userInfo: UserInfo) async -> SmartResponse

    @SpryableFunc
    func request(url: SmartURL,
                 parameters: Parameters,
                 userInfo: UserInfo,
                 completionQueue: DelayedQueue,
                 completion: @escaping ResponseClosure) -> SmartTasking
}
#endif
