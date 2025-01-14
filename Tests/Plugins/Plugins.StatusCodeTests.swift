import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class StatusCodePluginTests: XCTestCase {
    let session: FakeSmartURLSession = .init()

    func test_shouldNotIgnoreSuccess() {
        let subject = Plugins.StatusCode(shouldIgnore200th: false, shouldIgnoreNil: false, shouldIgnorePreviousError: false)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200), userInfo: .init()))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 0), userInfo: .init()))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: -1), userInfo: .init()))

        for code in StatusCode.Kind.allCases {
            XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue), userInfo: .init()), StatusCode(code), "\(code)")
        }

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 204), userInfo: .init()), StatusCode.noContent)
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404), userInfo: .init()), StatusCode(.notFound))

        // shouldIgnorePreviousError
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 304, error: RequestError.generic), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 400, error: RequestError.generic), userInfo: .init()))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 404, error: RequestError.generic), userInfo: .init()))

        // statusCode: nil
        XCTAssertThrowsError(try subject.verify(data: .testMake(), userInfo: .init()), StatusCode.none)

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        subject.prepare(.testMake(), request: requestable, session: session)
        subject.willSend(.testMake(), request: requestable, userInfo: .testMake(), session: session)
        subject.didReceive(.testMake(), request: requestable, data: .testMake(), userInfo: .testMake())
    }

    func test_shouldIgnoreSuccess() {
        let subject = Plugins.StatusCode(shouldIgnore200th: true, shouldIgnoreNil: true, shouldIgnorePreviousError: true)

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

        // shouldIgnorePreviousError
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 304, error: RequestError.generic), userInfo: .init()), StatusCode(.notModified))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400, error: RequestError.generic), userInfo: .init()), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404, error: RequestError.generic), userInfo: .init()), StatusCode(.notFound))

        // statusCode: nil
        XCTAssertNoThrowError(try subject.verify(data: .testMake(), userInfo: .init()))

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        subject.prepare(.testMake(), request: requestable, session: session)
        subject.willSend(.testMake(), request: requestable, userInfo: .testMake(), session: session)
        subject.didReceive(.testMake(), request: requestable, data: .testMake(), userInfo: .testMake())
    }
}
