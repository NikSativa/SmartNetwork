import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class RequestEncodingErrorTests: XCTestCase {
    func test_subname() {
        XCTAssertEqual(RequestEncodingError.other(.invalidValue(111, .init(codingPath: [], debugDescription: "descr"))).subname, ".other(EncodingError.invalidValue: 111 (Int). Debug description: descr)")
        XCTAssertEqual(RequestEncodingError.brokenURL.subname, "brokenURL")
        XCTAssertEqual(RequestEncodingError.brokenAddress.subname, "brokenAddress")
        XCTAssertEqual(RequestEncodingError.brokenHost.subname, "brokenHost")
        XCTAssertEqual(RequestEncodingError.cantEncodeImage.subname, "cantEncodeImage")
        XCTAssertEqual(RequestEncodingError.invalidJSON.subname, "invalidJSON")
    }
}
