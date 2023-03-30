import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class PluginsBearerTests: XCTestCase {
    func test_authToken() {
        let subject = Plugins.Bearer {
            return "my_token_string"
        }

        var userInfo: Parameters.UserInfo = .init()
        let parameters: Parameters = .testMake()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValue).andReturn()
        subject.prepare(parameters,
                        request: requestable,
                        userInfo: &userInfo)
        XCTAssertHaveReceived(requestable, .setValue, with: "Bearer my_token_string", "Authorization", countSpecifier: .exactly(1))
        XCTAssertTrue(userInfo.isEmpty)
        XCTAssertNoThrowError {
            try subject.verify(data: .testMake(), userInfo: .init())
        }
    }
}
