import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class StatusCodePluginTests: XCTestCase {
    func test_code() {
        let subject = Plugins.StatusCode()

        XCTAssertNotThrowsError(try subject.verify(data: .testMake(), userInfo: .init()))
        XCTAssertNotThrowsError(try subject.verify(data: .testMake(statusCode: 200), userInfo: .init()))

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 0), userInfo: .init()), StatusCode(0).unsafelyUnwrapped)
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: -1), userInfo: .init()), StatusCode(1023).unsafelyUnwrapped)

        for code in StatusCode.Kind.allCases {
            XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), StatusCode(code))
        }

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 204), userInfo: .init()), StatusCode.noContent)
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404), userInfo: .init()), StatusCode(.notFound))
    }
}
