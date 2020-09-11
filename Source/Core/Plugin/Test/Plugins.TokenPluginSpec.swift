import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class Plugins_Bearer_ProviderSpec: QuickSpec {
    override func spec() {
        describe("Plugins.Bearer.Provider") {
            var subject: Plugins.Bearer.Provider!
            var authTokenProvider: FakeAuthTokenProvider!

            beforeEach {
                authTokenProvider = .init()
                subject = .init(authTokenProvider: authTokenProvider)
            }

            describe("prepare") {
                var originalRequest: URLRequest!
                var info: PluginInfo!
                var actualUrlRequest: URLRequest!

                beforeEach {
                    originalRequest = .testMake(url: .testMake(string: "http://www.dodo.com"))
                    info = .testMake(request: originalRequest)

                    authTokenProvider.stub(.token).andReturn("my_token_string")

                    actualUrlRequest = subject.prepare(info)
                }

                it("should modify request") {
                    expect(actualUrlRequest).toNot(equal(originalRequest))

                    let expectedRequest = URLRequest.testMake(url: .testMake(string: "http://www.dodo.com"),
                                                              headers: ["Authorization": "Bearer my_token_string"])
                    expect(actualUrlRequest).to(equal(expectedRequest))
                }
            }

            describe("should not wait anything") {
                var actual: Bool!

                beforeEach {
                    actual = subject.should(wait: .testMake(), response: nil, with: nil, forRetryCompletion: { _ in })
                }

                it("should not modify request") {
                    expect(actual).to(beFalse())
                }
            }

            describe("should not map anything") {
                var actual: Data!
                var original: Data!

                beforeEach {
                    original = "some".data(using: .utf8)
                    actual = subject.map(response: original)
                }

                it("should not modify request") {
                    expect(actual).to(equal(original))
                }
            }
        }
    }
}
