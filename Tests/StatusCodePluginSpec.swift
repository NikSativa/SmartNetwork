import Foundation
import Nimble
import NSpry
import Quick
@testable import NRequest
@testable import NRequestTestHelpers

final class StatusCodePluginSpec: QuickSpec {
    override func spec() {
        describe("StatusCodePlugin") {
            var subject: Plugins.StatusCode!
            var userInfo: Parameters.UserInfo!

            beforeEach {
                subject = .init()
                userInfo = .init()
            }

            context("when status code is absent") {
                it("should pass") {
                    expect {
                        try subject.verify(data: .testMake(),
                                           userInfo: &userInfo)

                    }.toNot(throwError())
                }
            }

            context("when receiving status code 200") {
                it("should pass") {
                    expect {
                        try subject.verify(data: .testMake(statusCode: 200),
                                           userInfo: &userInfo)

                    }.toNot(throwError())
                }
            }

            context("when receiving status code 0..<1000") {
                it("should throw corresponding error") {
                    for code in 0..<1000 where code != 200 {
                        let error = StatusCode(code).unsafelyUnwrapped
                        if let typed = error.kind {
                            expect(typed.rawValue) == code
                        }
                        expect {
                            try subject.verify(data: .testMake(statusCode: code),
                                               userInfo: &userInfo)
                        }.to(throwError(error))
                    }
                }
            }
        }
    }
}
