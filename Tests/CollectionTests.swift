import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class CollectionTests: XCTestCase {
    func test_unwrap() {
        var subject: [Int] = []
        XCTAssertThrowsError(try subject.throwIfEmpty(), RequestDecodingError.brokenResponse)
        subject = [1]
        XCTAssertNotThrowsError(try subject.throwIfEmpty())
    }
}
