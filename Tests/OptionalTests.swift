import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class OptionalTests: XCTestCase {
    func test_unwrap() {
        var subject: Int?
        XCTAssertThrowsError(try subject.unwrap(), RequestDecodingError.brokenResponse)
        subject = 1
        XCTAssertNoThrowError(try subject.unwrap())
    }
}
