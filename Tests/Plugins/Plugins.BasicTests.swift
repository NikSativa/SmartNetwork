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
        try await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        let token = "Basic bXlfdG9rZW5fdXNlcm5hbWU6bXlfdG9rZW5fcGFzc3dvcmQ="
        XCTAssertHaveReceived(requestable, .setValueWithValue_Forhttpheaderfield, with: token, "Authorization", countSpecifier: .exactly(1))
        XCTAssertNoThrowError {
            try await subject.verify(parameters: parameters, userInfo: userInfo, response: .testMake())
        }
        XCTAssertTrue(userInfo.isEmpty)

        // should nothing happen
        let response: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        requestable.resetCallsAndStubs()

        await subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, response: response)
        try await subject.verify(parameters: parameters, userInfo: userInfo, response: .testMake())
        await subject.didFinish(parameters: parameters, userInfo: userInfo, response: response)

        XCTAssertEqual(response.url, .spry.testMake())
        XCTAssertNil(response.urlError)
    }
}
#endif
