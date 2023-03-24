import Foundation
import XCTest

#warning("mv to Spry")
@inline(__always)
public func XCTAssertEqualError(_ lhs: Error, _ rhs: Error, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(lhs as NSError, rhs as NSError, message(), file: file, line: line)
}

@inline(__always)
public func XCTAssertNotEqualError(_ lhs: Error, _ rhs: Error, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertNotEqual(lhs as NSError, rhs as NSError, message(), file: file, line: line)
}
