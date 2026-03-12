import Foundation
import XCTest
@testable import SmartNetwork

final class AnyErrorRetrierTests: XCTestCase {
    func test_subject() async {
        let subject = AnyErrorRetrier(attemptsCount: 3) { error in
            if case .generic = error.requestError {
                return .retry
            }
            return .doNotRetry
        }

        let result00 = await subject.retryOrFinish(attemptsCount: 0, isGenericError: false)
        let result01 = await subject.retryOrFinish(attemptsCount: 0, isGenericError: true)
        XCTAssertEqual(result00, .doNotRetry)
        XCTAssertEqual(result01, .retry)

        let result10 = await subject.retryOrFinish(attemptsCount: 1, isGenericError: false)
        let result11 = await subject.retryOrFinish(attemptsCount: 1, isGenericError: true)
        XCTAssertEqual(result10, .doNotRetry)
        XCTAssertEqual(result11, .retry)

        let result20 = await subject.retryOrFinish(attemptsCount: 2, isGenericError: false)
        let result21 = await subject.retryOrFinish(attemptsCount: 2, isGenericError: true)
        XCTAssertEqual(result20, .doNotRetry)
        XCTAssertEqual(result21, .retry)

        let result30 = await subject.retryOrFinish(attemptsCount: 3, isGenericError: false)
        let result31 = await subject.retryOrFinish(attemptsCount: 3, isGenericError: true)
        XCTAssertEqual(result30, .doNotRetry)
        XCTAssertEqual(result31, .doNotRetry)

        let result3330 = await subject.retryOrFinish(attemptsCount: 333, isGenericError: false)
        let result3331 = await subject.retryOrFinish(attemptsCount: 333, isGenericError: true)
        XCTAssertEqual(result3330, .doNotRetry)
        XCTAssertEqual(result3331, .doNotRetry)
    }
}

private extension AnyErrorRetrier {
    func retryOrFinish(attemptsCount: Int, isGenericError: Bool) -> RetryResult {
        let userInfo = UserInfo()
        userInfo.attemptsCount = attemptsCount
        let error: (any Error)? = isGenericError ? RequestError.generic : nil
        return retryOrFinish(result: .testMake(error: error),
                             url: .testMake(),
                             parameters: .testMake(),
                             userInfo: userInfo)
    }
}
