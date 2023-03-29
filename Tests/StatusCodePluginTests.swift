import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class StatusCodePluginTests: XCTestCase {
    func test_shouldNotIgnoreSuccess() {
        let subject = Plugins.StatusCode(shouldIgnore200th: false)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200), userInfo: .init()))

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 0), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: -1), userInfo: .init()))

        for code in StatusCode.Kind.allCases {
            XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), StatusCode(code), "\(code)")
        }

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 204), userInfo: .init()), StatusCode.noContent)
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404), userInfo: .init()), StatusCode(.notFound))
    }

    func test_shouldIgnoreSuccess() {
        let subject = Plugins.StatusCode(shouldIgnore200th: true)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200), userInfo: .init()))

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 0), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: -1), userInfo: .init()))

        for code in StatusCode.Kind.allCases {
            if code.isSuccess {
                XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), "\(code)")
            } else {
                XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), StatusCode(code), "\(code)")
            }
        }

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 204), userInfo: .init()))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404), userInfo: .init()), StatusCode(.notFound))
    }
}
