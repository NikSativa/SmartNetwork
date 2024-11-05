#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Foundation
import SpryKit
import Threading
import XCTest

@testable import SmartNetwork

@Spryable
final class FakeRequestManager: RequestManager, @unchecked Sendable {
    private var response: RequestResult?

    func fire<T>(_ response: RequestResult = .testMake(), _ closure: @Sendable @escaping () async throws -> T, completion: @escaping @Sendable (T?) -> Void) {
        self.response = response
        Task.detached { [completion] in
            let t = try? await closure()
            completion(t)
        }
    }

    func request(address: Address, parameters: Parameters, completionQueue: DelayedQueue, completion: @escaping ResponseClosure) -> SmartTasking {
        let sendable = USendable(completion)
        Queue.default.async { [sendable, response] in
            Queue.main.sync {
                sendable.value(response ?? .testMake())
            }
        }
        return spryify(arguments: address, parameters, completionQueue, completion)
    }
}
#endif
