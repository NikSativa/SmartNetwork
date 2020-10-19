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
            var authToken: FakeKeyedStorage<String>!

            beforeEach {
                authToken = .init()
                subject = .init(authToken: authToken)
            }

            describe("prepare") {
                var originalRequest: URLRequest!
                var info: RequestInfo!

                beforeEach {
                    originalRequest = .testMake(url: .testMake("http://www.some.com"))
                    info = .testMake(request: originalRequest)

                    authToken.stub(.value).andReturn("my_token_string")

                    subject.prepare(info)
                }

                it("should modify request") {
                    expect(info.request).toNot(equal(originalRequest))

                    let expectedRequest: URLRequest = .testMake(url: .testMake("http://www.some.com"),
                                                                headers: ["Authorization": "Bearer my_token_string"])
                    expect(info.request).to(equal(expectedRequest))
                }
            }
        }
    }
}
