import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class Plugins_JSONHeadersTests: XCTestCase {
    func test_authToken() async throws {
        let subject = Plugins.JSONHeaders()

        let userInfo: UserInfo = .testMake()
        let parameters: Parameters = .testMake()
        let session: FakeSmartURLSession = .init()
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

        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        XCTAssertHaveReceived(requestable, .setValue, countSpecifier: .atLeast(4))
        requestable.resetCallsAndStubs()

        XCTAssertNoThrowError {
            try subject.verify(parameters: parameters, userInfo: userInfo, data: .testMake())
        }
        XCTAssertTrue(userInfo.isEmpty)

        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: .testMake())

        let data: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)

        XCTAssertHaveNotReceived(requestable, .setValue)
    }
}
