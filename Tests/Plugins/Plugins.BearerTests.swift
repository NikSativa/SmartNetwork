import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class PluginsBearerTests: XCTestCase {
    func test_authToken() {
        let subject = Plugins.AuthBearer {
            return "my_token_string"
        }

        let parameters: Parameters = .testMake()
        let session: FakeSmartURLSession = .init()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValue).andReturn()
        subject.prepare(parameters, request: requestable, session: session)
        XCTAssertHaveReceived(requestable, .setValue, with: "Bearer my_token_string", "Authorization", countSpecifier: .exactly(1))
        XCTAssertNoThrowError {
            try subject.verify(data: .testMake(), userInfo: .init())
        }
        XCTAssertTrue(parameters.userInfo.isEmpty)
    }
}
