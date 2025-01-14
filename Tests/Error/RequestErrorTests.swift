import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class RequestErrorTests: XCTestCase {
    func test_wrapAnyError() {
        let actual1: Error = NSError(domain: "111", code: 212, userInfo: nil)
        let expected1: RequestError = .other(actual1)
        XCTAssertEqualError(actual1.requestError, expected1)
        XCTAssertEqualError(RequestError(actual1), expected1)

        let actual2 = URLError(.cannotConnectToHost)
        let expected2 = RequestError.connection(actual2)
        XCTAssertEqualError(actual2.requestError, expected2)
        XCTAssertEqualError(RequestError(actual2), expected2)

        let actual3 = RequestEncodingError.invalidJSON
        let expected3 = RequestError.encoding(actual3)
        XCTAssertEqualError(actual3.requestError, expected3)
        XCTAssertEqualError(RequestError(actual3), expected3)

        let actual4 = RequestDecodingError.brokenResponse
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

        let actual8 = EncodingError.invalidValue(11, .init(codingPath: [], debugDescription: ""))
        let expected8 = RequestError.encoding(.other(actual8))
        XCTAssertEqualError(actual8.requestError, expected8)
        XCTAssertEqualError(RequestError(actual8), expected8)

        let actual9 = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        let expected9 = RequestError.decoding(.other(actual9))
        XCTAssertEqualError(actual9.requestError, expected9)
        XCTAssertEqualError(RequestError(actual9), expected9)

        let actual10 = RequestError.statusCode(.noContent)
        let expected10 = actual10
        XCTAssertEqualError(actual10.requestError, expected10)
        XCTAssertEqualError(RequestError(actual10), expected10)

        let actual11 = RequestError.other(RequestError.other(StatusCode.noContent))
        let expected11 = RequestError.statusCode(.noContent)
        XCTAssertEqualError(actual11.requestError, expected11)
        XCTAssertEqualError(RequestError(actual11), expected11)
    }

    func test_subname() {
        XCTAssertEqual(RequestError.generic.subname, "generic")
        XCTAssertEqual(StatusCode(.forbidden).subname, "forbidden(403)")
        XCTAssertEqual(RequestEncodingError.brokenAddress.subname, "brokenAddress")
        XCTAssertEqual(RequestDecodingError.brokenResponse.subname, "brokenResponse")
        XCTAssertEqual(RequestError.connection(.init(.badURL)).subname, "connection(URLError -1000)")

        XCTAssertEqual(RequestError.other(NSError(domain: "descr", code: 111)).subname, "other(Error Domain=descr Code=111 \"(null)\")")
        XCTAssertEqual(RequestError.other(StatusCode(.forbidden)).subname, "other(forbidden(403))")
        XCTAssertEqual(RequestError.encoding(.brokenURL).subname, "encoding(.brokenURL)")
        XCTAssertEqual(RequestError.decoding(.nilResponse).subname, "decoding(.nilResponse)")
        XCTAssertEqual(RequestError.statusCode(.noContent).subname, "statusCode(.noContent(204))")
    }
}
