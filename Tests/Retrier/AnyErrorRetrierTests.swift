import Foundation
import XCTest

@testable import SmartNetwork

final class AnyErrorRetrierTests: XCTestCase {
    func test_subject() {
        let subject = AnyErrorRetrier(attemptsCount: 3) { error in
            if case .generic = error.requestError {
                return .retry
            }
            return .doNotRetry
        }

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 0, isGenericError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 0, isGenericError: true), .retry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 1, isGenericError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 1, isGenericError: true), .retry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 2, isGenericError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 2, isGenericError: true), .retry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 3, isGenericError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 3, isGenericError: true), .doNotRetry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 333, isGenericError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 333, isGenericError: true), .doNotRetry)
    }
}

private extension AnyErrorRetrier {
    func retryOrFinish(attemptsCount: Int, isGenericError: Bool) -> RetryResult {
        let userInfo = UserInfo()
        userInfo.attemptsCount = attemptsCount
        let error: (any Error)? = isGenericError ? RequestError.generic : nil
        return retryOrFinish(result: .testMake(error: error),
                             address: .testMake(),
                             parameters: .testMake(),
                             userInfo: userInfo)
    }
}
