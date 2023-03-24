import Foundation
import XCTest

#warning("mv to Spry")
@inline(__always)
@discardableResult
public func XCTAssertNotThrowsError<T>(_ expression: @autoclosure () throws -> T,
                                       _ message: @autoclosure () -> String = "",
                                       file: StaticString = #file,
                                       line: UInt = #line) -> T? {
    do {
        return try expression()
    } catch {
        XCTFail(message() + ". error: " + error.localizedDescription, file: file, line: line)
        return nil
    }
}

@inline(__always)
public func XCTAssertThrowsError(_ expression: @autoclosure () throws -> some Any,
                                 _ error: @autoclosure () -> Error,
                                 _ message: @autoclosure () -> String = "",
                                 file: StaticString = #file,
                                 line: UInt = #line) {
    XCTAssertThrowsError(try expression(), message(), file: file, line: line) { thrown in
        XCTAssertEqualError(thrown, error(), message(), file: file, line: line)
    }
}
