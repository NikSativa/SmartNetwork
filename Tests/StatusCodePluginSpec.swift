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

            beforeEach {
                subject = .init()
            }

            context("when status code is absent") {
                it("should pass") {
                    expect({ try subject.verify(data: .testMake()) }).toNot(throwError())
                }
            }

            context("when receiving status code 200") {
                it("should pass") {
                    expect({ try subject.verify(data: .testMake(statusCode: 200)) }).toNot(throwError())
                }
            }

            context("when receiving status code 0..<1000") {
                it("should throw corresponding error") {
                    let codes: [Int: StatusCode] = [204: .noContent,
                                                    400: .badRequest,
                                                    401: .unauthorized,
                                                    403: .forbidden,
                                                    404: .notFound,
                                                    408: .timeout,
                                                    426: .upgradeRequired,
                                                    500: .serverError]

                    for code in 0..<1000 where code != 200 {
                        let error = codes[code] ?? .other(code)
                        expect({ try subject.verify(data: .testMake(statusCode: code)) }).to(throwError(error))
                    }
                }
            }
        }
    }
}
