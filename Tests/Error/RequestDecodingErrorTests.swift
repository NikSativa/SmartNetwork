import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class RequestDecodingErrorTests: XCTestCase {
    func test_subname() {
        XCTAssertEqual(RequestDecodingError.other(.dataCorrupted(.init(codingPath: [], debugDescription: "descr"))).subname, ".other(DecodingError.dataCorrupted: Data was corrupted. Debug description: descr)")
        XCTAssertEqual(RequestDecodingError.brokenImage.subname, "brokenImage")
        XCTAssertEqual(RequestDecodingError.brokenResponse.subname, "brokenResponse")
        XCTAssertEqual(RequestDecodingError.nilResponse.subname, "nilResponse")
        XCTAssertEqual(RequestDecodingError.emptyResponse.subname, "emptyResponse")
    }
}
