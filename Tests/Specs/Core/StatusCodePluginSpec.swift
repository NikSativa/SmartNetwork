import Foundation
import UIKit

import Quick
import Nimble
import NSpry

@testable import NRequest

class StatusCodePluginSpec: QuickSpec {
    override func spec() {
        describe("StatusCodePlugin") {
            var subject: Plugins.StatusCode!

            beforeEach {
                subject = .init()
            }

            context("when status code is absent") {
                it("should pass") {
                    expect({ try subject.verify(httpStatusCode: nil, header: [:], data: nil, error: nil) }).toNot(throwError())
                }
            }

            context("when receiving status code 200") {
                it("should pass") {
                    expect({ try subject.verify(httpStatusCode: 200, header: [:], data: nil, error: nil) }).toNot(throwError())
                }
            }

            context("when receiving status code 204") {
                it("should throw error") {
                    expect({ try subject.verify(httpStatusCode: 204, header: [:], data: nil, error: nil) }).to(throwError(StatusCode.noContent))
                }
            }

            context("when receiving status code 400") {
                it("should throw error") {
                    expect({ try subject.verify(httpStatusCode: 400, header: [:], data: nil, error: nil) }).to(throwError(StatusCode.badRequest))
                }
            }

            context("when receiving status code 401") {
                it("should throw error") {
                    expect({ try subject.verify(httpStatusCode: 401, header: [:], data: nil, error: nil) }).to(throwError(StatusCode.unauthorized))
                }
            }

            context("when receiving status code 404") {
                it("should throw error") {
                    expect({ try subject.verify(httpStatusCode: 404, header: [:], data: nil, error: nil) }).to(throwError(StatusCode.notFound))
                }
            }

            context("when receiving status code 500") {
                it("should throw error") {
                    expect({ try subject.verify(httpStatusCode: 500, header: [:], data: nil, error: nil) }).to(throwError(StatusCode.serverError))
                }
            }

            context("when receiving unknown status code") {
                it("should throw error") {
                    expect({ try subject.verify(httpStatusCode: 123, header: [:], data: nil, error: nil) }).to(throwError(StatusCode.other(123)))
                }
            }
        }
    }
}
