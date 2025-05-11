import Foundation
import SmartNetwork
import XCTest

final class StatusCodeTests: XCTestCase {
    func test_init() {
        for code in 0...1000 {
            let error = StatusCode(code: code)
            XCTAssertNotNil(error, "\(code)")
            XCTAssertEqual(error.code, code)
        }

        XCTAssertEqual(StatusCode(.accepted).kind, .accepted)
        XCTAssertEqual(StatusCode(.lengthRequired).kind, .lengthRequired)
        XCTAssertEqual(StatusCode(.lengthRequired).code, 411)
    }

    func test_name() {
        XCTAssertEqual(StatusCode.Kind.lengthRequired.name, "lengthRequired")
    }

    func test_description() {
        XCTAssertEqual(StatusCode(code: 555).description, "StatusCode.unknown(555)")
        XCTAssertEqual(StatusCode(code: 545).debugDescription, "StatusCode.unknown(545)")

        XCTAssertEqual(StatusCode(.lengthRequired).description, "StatusCode.lengthRequired(411)")
        XCTAssertEqual(StatusCode(.alreadyReported).debugDescription, "StatusCode.alreadyReported(208)")
    }

    func test_subname() {
        for code in 0...1000 {
            let error = StatusCode(code: code)
            XCTAssertNotNil(error, "\(code)")
            XCTAssertEqual(error.code, code)

            let subname: String = error.kind.map {
                return String(reflecting: $0).components(separatedBy: ".").last ?? ""
            } ?? "unknown"
            XCTAssertEqual(error.subname, subname + "(\(code))")
        }
    }
}
