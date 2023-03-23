// import Foundation
// import Nimble
// import NSpry
// import NSpry_Nimble
// import Quick
//
// @testable import NRequest
// @testable import NRequestTestHelpers
//
// final class Plugins_Bearer_ProviderSpec: QuickSpec {
//    override func spec() {
//        describe("Plugins.Bearer") {
//            var subject: Plugin!
//            var authTokenProvider: Plugins.TokenProvider!
//
//            beforeEach {
//                authTokenProvider = {
//                    return "my_token_string"
//                }
//
//                subject = ModuleFactory().bearerPlugin(tokenProvider: authTokenProvider)
//            }
//
//            describe("prepare") {
//                var parameters: Parameters!
//                var requestable: FakeURLRequestWrapper!
//
//                beforeEach {
//                    parameters = .testMake()
//                    requestable = .init()
//                    requestable.stub(.setValue).andReturn()
//
//                    subject.prepare(parameters,
//                                    request: requestable,
//                                    userInfo: &parameters.userInfo)
//                }
//
//                it("should modify request") {
//                    expect(requestable).to(haveReceived(.setValue, with: "Bearer my_token_string", "Authorization"))
//                }
//            }
//        }
//    }
// }
