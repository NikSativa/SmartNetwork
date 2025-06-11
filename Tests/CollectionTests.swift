import Foundation
import SpryKit
import XCTest
@testable import SmartNetwork

final class CollectionTests: XCTestCase {
    func test_throwIfEmpty() {
        var subject: [Int] = []
        XCTAssertThrowsError(try subject.throwIfEmpty(), RequestDecodingError.brokenResponse)

        subject = [1]
        XCTAssertNoThrowError(try subject.throwIfEmpty())
    }

    func test_throwCustomErrorIfEmpty() {
        var subject: [Int] = []
        XCTAssertThrowsError(try subject.throwIfEmpty(RequestError.generic), RequestError.generic)

        subject = [1]
        XCTAssertNoThrowError(try subject.throwIfEmpty(RequestError.generic))
    }

    func test_nilIfEmpty() {
        var subject: [Int]? = nil
        XCTAssertEqual(subject.nilIfEmpty, nil)

        subject = []
        XCTAssertEqual(subject.nilIfEmpty, nil)

        subject = [1]
        XCTAssertEqual(subject.nilIfEmpty, [1])
    }
}
