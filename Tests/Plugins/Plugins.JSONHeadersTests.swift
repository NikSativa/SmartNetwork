import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class Plugins_JSONHeadersTests: XCTestCase {
    func test_authToken() throws {
        let subject = Plugins.JSONHeaders()

        let parameters: Parameters = .testMake()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.url).andReturn(URL.spry.testMake("https://www.apple.com"))
        requestable.stub(.value).with("Host").andReturn(nil)
        requestable.stub(.setValue).with("www.apple.com", "Host").andReturn()

        requestable.stub(.value).with("Accept").andReturn(nil)
        requestable.stub(.setValue).with("application/json, text/plain, */*", "Accept").andReturn()

        requestable.stub(.value).with("Accept-Encoding").andReturn(nil)
        requestable.stub(.setValue).with("gzip, deflate, br", "Accept-Encoding").andReturn()

        requestable.stub(.value).with("Connection").andReturn(nil)
        requestable.stub(.setValue).with("keep-alive", "Connection").andReturn()

        subject.prepare(parameters, request: requestable)
        XCTAssertHaveReceived(requestable, .setValue, countSpecifier: .atLeast(4))
        requestable.resetCallsAndStubs()

        XCTAssertNoThrowError {
            try subject.verify(data: .testMake(), userInfo: .init())
        }
        XCTAssertTrue(parameters.userInfo.isEmpty)

        subject.willSend(parameters, request: requestable, userInfo: .testMake())
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)

        XCTAssertHaveNotReceived(requestable, .setValue)
    }
}
