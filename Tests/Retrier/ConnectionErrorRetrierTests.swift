import Foundation
import XCTest
@testable import SmartNetwork

final class ConnectionErrorRetrierTests: XCTestCase {
    func test_subject() async {
        let subject = ConnectionErrorRetrier(attemptsCount: 3, result: .doNotRetry)

        let result00 = await subject.retryOrFinish(attemptsCount: 0, isConnectionError: false)
        let result01 = await subject.retryOrFinish(attemptsCount: 0, isConnectionError: true)
        XCTAssertEqual(result00, .doNotRetry)
        XCTAssertEqual(result01, .retry)

        let result10 = await subject.retryOrFinish(attemptsCount: 1, isConnectionError: false)
        let result11 = await subject.retryOrFinish(attemptsCount: 1, isConnectionError: true)
        XCTAssertEqual(result10, .doNotRetry)
        XCTAssertEqual(result11, .retry)

        let result20 = await subject.retryOrFinish(attemptsCount: 2, isConnectionError: false)
        let result21 = await subject.retryOrFinish(attemptsCount: 2, isConnectionError: true)
        XCTAssertEqual(result20, .doNotRetry)
        XCTAssertEqual(result21, .retry)

        let result30 = await subject.retryOrFinish(attemptsCount: 3, isConnectionError: false)
        let result31 = await subject.retryOrFinish(attemptsCount: 3, isConnectionError: true)
        XCTAssertEqual(result30, .doNotRetry)
        XCTAssertEqual(result31, .doNotRetry)

        let result3330 = await subject.retryOrFinish(attemptsCount: 333, isConnectionError: false)
        let result3331 = await subject.retryOrFinish(attemptsCount: 333, isConnectionError: true)
        XCTAssertEqual(result3330, .doNotRetry)
        XCTAssertEqual(result3331, .doNotRetry)
    }
}

private extension ConnectionErrorRetrier {
    func retryOrFinish(attemptsCount: Int, isConnectionError: Bool) -> RetryResult {
        let userInfo = UserInfo()
        userInfo.attemptsCount = attemptsCount
        let error: (any Error)? = isConnectionError ? URLError(.notConnectedToInternet) : nil
        return retryOrFinish(result: .testMake(error: error), url: .testMake(),
                             parameters: .testMake(),
                             userInfo: userInfo)
    }
}
