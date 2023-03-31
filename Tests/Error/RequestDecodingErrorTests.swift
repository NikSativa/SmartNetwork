import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestDecodingErrorTests: XCTestCase {
    func test_subname() {
        XCTAssertEqual(RequestDecodingError.other(.dataCorrupted(.init(codingPath: [], debugDescription: "descr"))).subname, ".other(Swift.DecodingError.dataCorrupted(Swift.DecodingError.Context(codingPath: [], debugDescription: \"descr\", underlyingError: nil)))")
        XCTAssertEqual(RequestDecodingError.brokenImage.subname, "brokenImage")
        XCTAssertEqual(RequestDecodingError.brokenResponse.subname, "brokenResponse")
        XCTAssertEqual(RequestDecodingError.nilResponse.subname, "nilResponse")
    }
}
