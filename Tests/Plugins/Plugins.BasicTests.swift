#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class PluginsBasicTests: XCTestCase {
    func test_authToken() async throws {
        let session: FakeSmartURLSession = .init()
        let subject = Plugins.AuthBasic {
            return .init(username: "my_token_username", password: "my_token_password")
        }

        let parameters: Parameters = .testMake()
        let userInfo: UserInfo = .testMake()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValueWithValue_Forhttpheaderfield).andReturn()
        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        let token = "Basic bXlfdG9rZW5fdXNlcm5hbWU6bXlfdG9rZW5fcGFzc3dvcmQ="
        XCTAssertHaveReceived(requestable, .setValueWithValue_Forhttpheaderfield, with: token, "Authorization", countSpecifier: .exactly(1))
        XCTAssertNoThrowError {
            try subject.verify(parameters: parameters, userInfo: userInfo, data: .testMake())
        }
        XCTAssertTrue(userInfo.isEmpty)

        // should nothing happen
        let data: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        requestable.resetCallsAndStubs()

        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: data)
        try subject.verify(parameters: parameters, userInfo: userInfo, data: .testMake())
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)
    }
}
#endif
