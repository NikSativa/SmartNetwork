import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class StatusCodePluginTests: XCTestCase {
    func test_shouldNotIgnoreSuccess() {
        let subject = Plugins.StatusCode(shouldIgnore200th: false)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200), userInfo: .init()))

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 0), userInfo: .init()))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: -1), userInfo: .init()))

        for code in StatusCode.Kind.allCases {
            XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), StatusCode(code), "\(code)")
        }

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 204), userInfo: .init()), StatusCode.noContent)
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404), userInfo: .init()), StatusCode(.notFound))

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        subject.prepare(.testMake(), request: requestable)
        subject.willSend(.testMake(), request: requestable, userInfo: .testMake())
        subject.didReceive(.testMake(), request: requestable, data: .testMake(), userInfo: .testMake())
    }

    func test_shouldIgnoreSuccess() {
        let subject = Plugins.StatusCode(shouldIgnore200th: true)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200), userInfo: .init()))

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 0), userInfo: .init()))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: -1), userInfo: .init()))

        for code in StatusCode.Kind.allCases {
            if (200..<300).contains(code.rawValue) {
                XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), "\(code)")
            } else {
                XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), StatusCode(code), "\(code)")
            }
        }

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 204), userInfo: .init()))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404), userInfo: .init()), StatusCode(.notFound))

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        subject.prepare(.testMake(), request: requestable)
        subject.willSend(.testMake(), request: requestable, userInfo: .testMake())
        subject.didReceive(.testMake(), request: requestable, data: .testMake(), userInfo: .testMake())
    }
}
