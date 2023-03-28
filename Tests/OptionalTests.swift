import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class OptionalTests: XCTestCase {
    func test_unwrap() {
        var subject: Int?
        XCTAssertThrowsError(try subject.unwrap(), RequestDecodingError.brokenResponse)
        subject = 1
        XCTAssertNotThrowsError(try subject.unwrap())
    }

    func test_unwrap_array() {
        var subject: [Int]? = nil
        XCTAssertEqual(subject.unwrapOrEmpty(), [])
        subject = [1]
        XCTAssertEqual(subject.unwrapOrEmpty(), [1])
    }

    func test_unwrap_dictionary() {
        var subject: [Int: Int]? = nil
        XCTAssertEqual(subject.unwrapOrEmpty(), [:])
        subject = [1: 1]
        XCTAssertEqual(subject.unwrapOrEmpty(), [1: 1])
    }
}
