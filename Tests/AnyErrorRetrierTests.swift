import Foundation
import XCTest

@testable import SmartNetwork

final class AnyErrorRetrierTests: XCTestCase {
    func test_subject() {
        let subject = AnyErrorRetrier(attemptsCount: 2, result: .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 0), .retry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 1), .retry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 2), .doNotRetry)
    }
}

private extension AnyErrorRetrier {
    func retryOrFinish(attemptsCount: Int) -> RetryResult {
        let userInfo = UserInfo()
        userInfo.attemptsCount = attemptsCount
        return retryOrFinish(result: .testMake(), address: .testMake(), parameters: .testMake(), userInfo: userInfo)
    }
}

// MARK: - RetryResult + Equatable

extension RetryResult: Equatable {
    public static func ==(lhs: SmartNetwork.RetryResult, rhs: SmartNetwork.RetryResult) -> Bool {
        switch (lhs, rhs) {
        case (.doNotRetry, .doNotRetry),
             (.retry, .retry):
            return true
        case (.retryWithDelay(let a), .retryWithDelay(let b)):
            return a == b
        case (.doNotRetryWithError(let a), .doNotRetryWithError(let b)):
            return (a as NSError) == (b as NSError)
        case (.doNotRetry, _),
             (.doNotRetryWithError, _),
             (.retry, _),
             (.retryWithDelay, _):
            return false
        }
    }
}
