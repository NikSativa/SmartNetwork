#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class StatusCodePluginTests: XCTestCase {
    let session: FakeSmartURLSession = .init()

    func test_shouldNotIgnoreSuccess() async {
        let subject = Plugins.StatusCode(shouldIgnore200th: false, shouldIgnoreNil: false, shouldIgnorePreviousError: false)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200)))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200)))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 0)))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: -1)))

        for code in StatusCode.Kind.allCases {
            XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue)), StatusCode(code), "\(code)")
        }

        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 204)), StatusCode.noContent)
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400)), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404)), StatusCode(.notFound))

        // shouldIgnorePreviousError
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 304, error: RequestError.generic)))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 400, error: RequestError.generic)))
        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 404, error: RequestError.generic)))

        // statusCode: nil
        XCTAssertThrowsError(try subject.verify(data: .testMake()), StatusCode.none)

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        await subject.prepare(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        subject.willSend(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        subject.didReceive(parameters: .testMake(), userInfo: .testMake(), request: requestable, data: .testMake())
    }

    func test_shouldIgnoreSuccess() async {
        let subject = Plugins.StatusCode(shouldIgnore200th: true, shouldIgnoreNil: true, shouldIgnorePreviousError: true)

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 200)))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 0)))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: -1)))

        for code in StatusCode.Kind.allCases {
            if (200..<300).contains(code.rawValue) {
                XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: code.rawValue)), "\(code)")
            } else {
                XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: code.rawValue)), StatusCode(code), "\(code)")
            }
        }

        XCTAssertNoThrowError(try subject.verify(data: .testMake(statusCode: 204)))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400)), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404)), StatusCode(.notFound))

        // shouldIgnorePreviousError
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 304, error: RequestError.generic)), StatusCode(.notModified))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 400, error: RequestError.generic)), StatusCode(.badRequest))
        XCTAssertThrowsError(try subject.verify(data: .testMake(statusCode: 404, error: RequestError.generic)), StatusCode(.notFound))

        // statusCode: nil
        XCTAssertNoThrowError(try subject.verify(data: .testMake()))

        // should nothing happen
        let requestable: FakeURLRequestRepresentation = .init()
        await subject.prepare(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        subject.willSend(parameters: .testMake(), userInfo: .testMake(), request: requestable, session: session)
        subject.didReceive(parameters: .testMake(), userInfo: .testMake(), request: requestable, data: .testMake())
    }
}

private extension Plugin {
    func verify(data: SmartResponse) throws {
        try verify(parameters: .testMake(), userInfo: .testMake(), data: data)
    }
}
#endif
