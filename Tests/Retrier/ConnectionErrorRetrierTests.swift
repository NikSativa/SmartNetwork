import Foundation
import XCTest
@testable import SmartNetwork

final class ConnectionErrorRetrierTests: XCTestCase {
    func test_subject() {
        let subject = ConnectionErrorRetrier(attemptsCount: 3, result: .doNotRetry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 0, isConnectionError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 0, isConnectionError: true), .retry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 1, isConnectionError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 1, isConnectionError: true), .retry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 2, isConnectionError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 2, isConnectionError: true), .retry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 3, isConnectionError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 3, isConnectionError: true), .doNotRetry)

        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 333, isConnectionError: false), .doNotRetry)
        XCTAssertEqual(subject.retryOrFinish(attemptsCount: 333, isConnectionError: true), .doNotRetry)
    }
}

private extension ConnectionErrorRetrier {
    func retryOrFinish(attemptsCount: Int, isConnectionError: Bool) -> RetryResult {
        let userInfo = UserInfo()
        userInfo.attemptsCount = attemptsCount
        let error: (any Error)? = isConnectionError ? URLError(.notConnectedToInternet) : nil
        return retryOrFinish(result: .testMake(error: error),
                             address: .testMake(),
                             parameters: .testMake(),
                             userInfo: userInfo)
    }
}
