import Foundation
import NSpry
import XCTest

@testable import NRequest

final class LoggerTests: XCTestCase {
    func test_logger() {
        var text: String?
        var file: String?
        var method: String?
        var line: Int?

        Logger.logger = {
            text = $0
            file = $1
            method = $2
            line = $3
        }
        Logger.log("text")

        XCTAssertEqual(text, "text")
        XCTAssertEqual(file?.components(separatedBy: "/").last, "LoggerTests.swift")
        XCTAssertEqual(method, "test_logger()")
        XCTAssertEqual(line, 20)
    }
}
