import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestEncodingErrorTests: XCTestCase {
    func test_subname() {
        XCTAssertEqual(RequestEncodingError.other(.invalidValue(111, .init(codingPath: [], debugDescription: "descr"))).subname, ".other(Swift.EncodingError.invalidValue(111, Swift.EncodingError.Context(codingPath: [], debugDescription: \"descr\", underlyingError: nil)))")
        XCTAssertEqual(RequestEncodingError.invalidParameters.subname, "invalidParameters")
        XCTAssertEqual(RequestEncodingError.brokenURL.subname, "brokenURL")
        XCTAssertEqual(RequestEncodingError.brokenAddress.subname, "brokenAddress")
        XCTAssertEqual(RequestEncodingError.brokenHost.subname, "brokenHost")
        XCTAssertEqual(RequestEncodingError.cantEncodeImage.subname, "cantEncodeImage")
        XCTAssertEqual(RequestEncodingError.invalidJSON.subname, "invalidJSON")
    }
}
