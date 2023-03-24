import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestErrorTests: XCTestCase {
    func test_wrapAnyError() {
        let actual1: Error = NSError(domain: "111", code: 212, userInfo: nil)
        let expected1: RequestError = .other(actual1)
        XCTAssertEqualError(actual1.requestError, expected1)
        XCTAssertEqualError(RequestError(actual1), expected1)

        let actual2 = URLError(.cannotConnectToHost)
        let expected2 = RequestError.connection(actual2, .cannotConnectToHost)
        XCTAssertEqualError(actual2.requestError, expected2)
        XCTAssertEqualError(RequestError(actual2), expected2)

        let actual3 = EncodingError.invalidJSON
        let expected3 = RequestError.encoding(actual3)
        XCTAssertEqualError(actual3.requestError, expected3)
        XCTAssertEqualError(RequestError(actual3), expected3)

        let actual4 = DecodingError.brokenResponse
        let expected4 = RequestError.decoding(actual4)
        XCTAssertEqualError(actual4.requestError, expected4)
        XCTAssertEqualError(RequestError(actual4), expected4)

        let actual5 = StatusCode(.forbidden)
        let expected5 = RequestError.statusCode(actual5)
        XCTAssertEqualError(actual5.requestError, expected5)
        XCTAssertEqualError(RequestError(actual5), expected5)

        let actual6 = RequestError.generic
        let expected6 = actual6
        XCTAssertEqualError(actual6.requestError, expected6)
        XCTAssertEqualError(RequestError(actual6), expected6)

        let actual7 = RequestError.statusCode(.noContent)
        let expected7 = actual7
        XCTAssertEqualError(actual7.requestError, expected7)
        XCTAssertEqualError(RequestError(actual7), expected7)
    }
}
