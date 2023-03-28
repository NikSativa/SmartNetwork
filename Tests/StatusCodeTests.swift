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
        XCTAssertEqual(StatusCode(.lenghtRequired).kind, .lenghtRequired)
        XCTAssertEqual(StatusCode(.lenghtRequired).code, 411)
        XCTAssertTrue(StatusCode(.accepted).isSuccess)
    }

    func test_name() {
        XCTAssertEqual(StatusCode.Kind.lenghtRequired.name, "lenghtRequired")
    }

    func test_description() {
        XCTAssertEqual(StatusCode(.lenghtRequired).description, "StatusCode 411 (lenghtRequired)")
        XCTAssertEqual(StatusCode(.lenghtRequired).debugDescription, "StatusCode 411 (lenghtRequired)")
        XCTAssertEqual(StatusCode(.lenghtRequired).localizedDescription, "StatusCode 411 (lenghtRequired)")
    }
}
