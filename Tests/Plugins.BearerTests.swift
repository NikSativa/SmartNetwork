import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class PluginsBearerTests: XCTestCase {
    func test_authToken() {
        let subject = Plugins.BearerPlugin {
            return "my_token_string"
        }

        var parameters: Parameters = .testMake()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValue).andReturn()
        subject.prepare(parameters,
                        request: requestable,
                        userInfo: &parameters.userInfo)
        XCTAssertHaveReceived(requestable, .setValue, with: "Bearer my_token_string", "Authorization", countSpecifier: .exactly(1))
    }
}
