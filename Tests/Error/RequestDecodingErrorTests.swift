import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class RequestDecodingErrorTests: XCTestCase {
    func test_subname() {
        XCTAssertEqual(RequestDecodingError.other(.dataCorrupted(.init(codingPath: [], debugDescription: "descr"))).subname, ".other(Swift.DecodingError.dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: \"descr\", underlyingError: nil)))")
        XCTAssertEqual(RequestDecodingError.brokenImage.subname, "brokenImage")
        XCTAssertEqual(RequestDecodingError.brokenResponse.subname, "brokenResponse")
        XCTAssertEqual(RequestDecodingError.nilResponse.subname, "nilResponse")
        XCTAssertEqual(RequestDecodingError.emptyResponse.subname, "emptyResponse")
    }
}
