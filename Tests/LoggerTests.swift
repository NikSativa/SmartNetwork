import Foundation
import NSpry
import XCTest

@testable import NRequest

final class LoggerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        RS.logger = nil
    }

    func test_logger() {
        var text: String?
        var file: String?
        var method: String?
        var line: Int?

        RS.logger = {
            text = $0()
            file = $1
            method = $2
            line = $3
        }
        RS.log("text")

        XCTAssertEqual(text, "text")
        XCTAssertEqual(file?.components(separatedBy: "/").last, "LoggerTests.swift")
        XCTAssertEqual(method, "test_logger()")
        XCTAssertEqual(line, 25)
    }
}
