import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class RequestEncodingErrorTests: XCTestCase {
    func test_subname() {
        XCTAssertEqual(RequestEncodingError.other(.invalidValue(111, .init(codingPath: [], debugDescription: "descr"))).subname, ".other(Swift.EncodingError.invalidValue(111, Swift.EncodingError.Context(codingPath: [], debugDescription: \"descr\", underlyingError: nil)))")
        XCTAssertEqual(RequestEncodingError.brokenURL.subname, "brokenURL")
        XCTAssertEqual(RequestEncodingError.brokenAddress.subname, "brokenAddress")
        XCTAssertEqual(RequestEncodingError.brokenHost.subname, "brokenHost")
        XCTAssertEqual(RequestEncodingError.cantEncodeImage.subname, "cantEncodeImage")
        XCTAssertEqual(RequestEncodingError.invalidJSON.subname, "invalidJSON")
    }
}
