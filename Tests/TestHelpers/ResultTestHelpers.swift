import Foundation
import XCTest

@inline(__always)
func XCTAssertEqual<T>(_ lhs: Result<T, Error>,
                       _ rhs: T,
                       _ message: @autoclosure () -> String? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line)
where T: Equatable {
    let result: Bool =
        switch (lhs, rhs) {
        case (.success(let l), let r):
            l == r
        case (.failure, _):
            false
        }
    XCTAssertTrue(result, message() ?? "\(lhs) != \(rhs)", file: file, line: line)
}

@inline(__always)
func XCTAssertEqual<T>(_ lhs: Result<T, Error>,
                       _ rhs: some Error,
                       _ message: @autoclosure () -> String? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
    let result: Bool =
        switch (lhs, rhs) {
        case (.failure(let l), let r):
            (l as NSError) == (r as NSError)
        case (.success, _):
            false
        }
    XCTAssertTrue(result, message() ?? "\(lhs) != \(rhs)", file: file, line: line)
}

@inline(__always)
func XCTAssertEqual<T>(_ lhs: Result<T, Error>,
                       _ rhs: Result<T, Error>,
                       _ message: @autoclosure () -> String? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line)
where T: Equatable {
    let result: Bool =
        switch (lhs, rhs) {
        case (.failure(let l), .failure(let r)):
            (l as NSError) == (r as NSError)
        case (.success(let l), .success(let r)):
            l == r
        case (.failure, _),
             (.success, _):
            false
        }
    XCTAssertTrue(result, message() ?? "\(lhs) != \(rhs)", file: file, line: line)
}

extension Result {
    var error: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let failure):
            return failure
        }
    }

    func value<T>() -> T? where Success == T? {
        switch self {
        case .success(let success):
            return success
        case .failure:
            return nil
        }
    }
}
