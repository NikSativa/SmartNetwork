import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class PluginsBasicTests: XCTestCase {
    func test_authToken() {
        let subject = Plugins.Basic {
            return ("my_token_username", "my_token_password")
        }

        var userInfo: Parameters.UserInfo = .init()
        let parameters: Parameters = .testMake()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValue).andReturn()
        subject.prepare(parameters,
                        request: requestable,
                        userInfo: &userInfo)
        let token = "Basic bXlfdG9rZW5fdXNlcm5hbWU6bXlfdG9rZW5fcGFzc3dvcmQ="
        XCTAssertHaveReceived(requestable, .setValue, with: token, "Authorization", countSpecifier: .exactly(1))
        XCTAssertTrue(userInfo.isEmpty)
        XCTAssertNoThrowError {
            try subject.verify(data: .testMake(), userInfo: .init())
        }
    }
}
