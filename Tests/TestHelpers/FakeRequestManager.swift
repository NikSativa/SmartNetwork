#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SpryKit
import Threading
import XCTest

@testable import SmartNetwork

@Spryable
final class FakeRequestManager: RequestManager, @unchecked Sendable {
    private var response: RequestResult?

    @SpryableFunc
    func request(address: Address, parameters: Parameters, completionQueue: DelayedQueue, completion: @escaping ResponseClosure) -> SmartTasking
}
#endif
