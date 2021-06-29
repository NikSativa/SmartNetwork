import Foundation
import UIKit

import Quick
import Nimble
import NSpry

@testable import NRequest
@testable import NRequestTestHelpers

class Plugins_Bearer_ProviderSpec: QuickSpec {
    override func spec() {
        describe("Plugins.Bearer.Provider") {
            var subject: Plugins.Bearer!
            var authTokenProvider: FakeBearerTokenProvider!

            beforeEach {
                authTokenProvider = .init()
                subject = .init(tokenProvider: authTokenProvider)
            }

            describe("prepare") {
                var originalRequest: URLRequest!
                var info: RequestInfo!

                beforeEach {
                    originalRequest = .testMake(url: .testMake("http://www.some.com"))
                    info = .testMake(request: originalRequest)

                    authTokenProvider.stub(.token).andReturn("my_token_string")

                    subject.prepare(&info)
                }

                it("should modify request") {
                    expect(info.request) != originalRequest

                    let expectedRequest: URLRequest = .testMake(url: .testMake("http://www.some.com"),
                                                                headers: ["Authorization": "Bearer my_token_string"])
                    expect(info.request) == expectedRequest
                }
            }
        }
    }
}
