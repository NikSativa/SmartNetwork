import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class Plugins_Bearer_StorageSpec: QuickSpec {
    override func spec() {
        describe("Plugins.Bearer.Storage") {
            var subject: Plugins.Bearer.Storage!
            var authToken: FakeTokenStorage!

            beforeEach {
                authToken = .init()
                subject = .init(authToken: authToken)
            }

            describe("prepare") {
                var originalRequest: URLRequest!
                var info: PluginInfo!
                var actualUrlRequest: URLRequest!

                beforeEach {
                    originalRequest = .testMake(url: .testMake("http://www.some.com"))
                    info = .testMake(request: originalRequest)

                    authToken.stub(.token).andReturn("my_token_string")

                    actualUrlRequest = subject.prepare(info)
                }

                it("should modify request") {
                    expect(actualUrlRequest).toNot(equal(originalRequest))

                    let expectedRequest: URLRequest = .testMake(url: .testMake("http://www.some.com"),
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
        }
    }
}
