import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class CollectionTests: XCTestCase {
    func test_unwrap() {
        var subject: [Int] = []
        XCTAssertThrowsError(try subject.throwIfEmpty(), RequestDecodingError.brokenResponse)
        subject = [1]
        XCTAssertNoThrowError(try subject.throwIfEmpty())
    }
}
