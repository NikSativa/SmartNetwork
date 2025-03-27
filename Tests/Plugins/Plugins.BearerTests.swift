#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class PluginsBearerTests: XCTestCase {
    func test_authToken() async {
        let subject = Plugins.AuthBearer {
            return "my_token_string"
        }

        let parameters: Parameters = .testMake()
        let userInfo: UserInfo = .testMake()
        let session: FakeSmartURLSession = .init()
        let requestable: FakeURLRequestRepresentation = .init()
        requestable.stub(.setValueWithValue_Forhttpheaderfield).andReturn()
        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        XCTAssertHaveReceived(requestable, .setValueWithValue_Forhttpheaderfield, with: "Bearer my_token_string", "Authorization", countSpecifier: .exactly(1))
        XCTAssertNoThrowError {
            try subject.verify(parameters: parameters, userInfo: userInfo, data: .testMake())
        }
        XCTAssertTrue(userInfo.isEmpty)
    }
}
#endif
