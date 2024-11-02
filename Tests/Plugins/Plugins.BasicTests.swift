import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class PluginsBasicTests: XCTestCase {
    func test_authToken() throws {
        let subject = Plugins.AuthBasic {
            return .init(username: "my_token_username", password: "my_token_password")
        }

        let parameters: Parameters = .testMake()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValue).andReturn()
        subject.prepare(parameters,
                        request: requestable)
        let token = "Basic bXlfdG9rZW5fdXNlcm5hbWU6bXlfdG9rZW5fcGFzc3dvcmQ="
        XCTAssertHaveReceived(requestable, .setValue, with: token, "Authorization", countSpecifier: .exactly(1))
        XCTAssertNoThrowError {
            try subject.verify(data: .testMake(), userInfo: .init())
        }
        XCTAssertTrue(parameters.userInfo.isEmpty)

        // should nothing happen
        let data: RequestResult = .testMake(url: .spry.testMake(), statusCode: 222)
        requestable.resetCallsAndStubs()

        subject.willSend(parameters, request: requestable, userInfo: .testMake())
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)
    }
}
