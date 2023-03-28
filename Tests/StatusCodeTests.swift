import Foundation
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class StatusCodeTests: XCTestCase {
    func test_init() {
        for code in 0...1000 {
            let error = StatusCode(code: code)
            XCTAssertNotNil(error, "\(code)")
            XCTAssertEqual(error.code, code)
        }

        XCTAssertEqual(StatusCode(.accepted).kind, .accepted)
        XCTAssertEqual(StatusCode(.success).kind, .success)
        XCTAssertEqual(StatusCode(.success).code, 200)
    }
}
