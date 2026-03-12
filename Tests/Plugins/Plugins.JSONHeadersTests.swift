#if swift(>=6.0) && canImport(SwiftSyntax600)
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
        requestable.stub(.url_get).andReturn(URL.spry.testMake("https://www.apple.com"))
        requestable.stub(.valueWithForhttpheaderfield).with("Host").andReturn(nil)
        requestable.stub(.setValueWithValue_Forhttpheaderfield).with("www.apple.com", "Host").andReturn()

        requestable.stub(.valueWithForhttpheaderfield).with("Accept").andReturn(nil)
        requestable.stub(.setValueWithValue_Forhttpheaderfield).with("application/json, text/plain, */*", "Accept").andReturn()

        requestable.stub(.valueWithForhttpheaderfield).with("Accept-Encoding").andReturn(nil)
        requestable.stub(.setValueWithValue_Forhttpheaderfield).with("gzip, deflate, br", "Accept-Encoding").andReturn()

        requestable.stub(.valueWithForhttpheaderfield).with("Connection").andReturn(nil)
        requestable.stub(.setValueWithValue_Forhttpheaderfield).with("keep-alive", "Connection").andReturn()

        try await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        XCTAssertHaveReceived(requestable, .setValueWithValue_Forhttpheaderfield, countSpecifier: .atLeast(4))
        requestable.resetCallsAndStubs()

        XCTAssertNoThrowError {
            try await subject.verify(parameters: parameters, userInfo: userInfo, response: .testMake())
        }
        XCTAssertTrue(userInfo.isEmpty)

        await subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, response: .testMake())

        let response: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        try await subject.verify(parameters: parameters, userInfo: userInfo, response: response)
        await subject.didFinish(parameters: parameters, userInfo: userInfo, response: response)

        XCTAssertEqual(response.url, .spry.testMake())
        XCTAssertNil(response.urlError)

        XCTAssertHaveNotReceived(requestable, .setValueWithValue_Forhttpheaderfield)
    }
}
#endif
