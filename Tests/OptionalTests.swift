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
        XCTAssertNoThrowError(try subject.unwrap())
    }
}
