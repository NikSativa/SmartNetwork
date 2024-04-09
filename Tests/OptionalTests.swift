import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class OptionalTests: XCTestCase {
    func test_unwrap() {
        var subject: Int?
        XCTAssertThrowsError(try subject.unwrap(), RequestDecodingError.brokenResponse)
        subject = 1
        XCTAssertNoThrowError(try subject.unwrap())
    }
}
