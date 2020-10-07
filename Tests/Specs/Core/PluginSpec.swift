import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class PluginSpec: QuickSpec {
    private enum TestError: Error {
        case case1
    }

    private struct EmptyPlugin: Plugin {
        func verify(httpStatusCode code: Int?, header: [AnyHashable : Any], data: Data?, error: Error?) throws {
        }
    }

    private struct OverriddenPlugin: Plugin {
        func prepare(_ info: Info) -> URLRequest {
            return .testMake(url: .testMake("other.com"))
        }

        func willSend(_ info: Info) { }
        func didComplete(_ info: Info, response: Any?, error: Error?) { }
        func didStop(_ info: Info) { }

        func should(wait info: Info, response: URLResponse?, with error: Error?, forRetryCompletion: @escaping (_ shouldRetry: Bool) -> Void) -> Bool {
            forRetryCompletion(true)
            return true
        }

        func verify(httpStatusCode code: Int?, header: [AnyHashable : Any], data: Data?, error: Error?) throws {
            throw TestError.case1
        }
    }

    override func spec() {
        describe("default implementation of Plugin") {
            var subject: EmptyPlugin!
            var request: URLRequest!
            var info: PluginInfo!

            beforeEach {
                request = .testMake()
                info = .testMake(request: request)

                subject = .init()
            }

            it("should prepare") {
                expect(subject.prepare(info)).to(equal(request))
            }

            it("should willSend") {
                subject.willSend(info)
                expect(subject).toNot(beNil())
            }

            it("should didFinish") {
                subject.didFinish(info, response: nil, with: nil, statusCode: nil)
                expect(subject).toNot(beNil())
            }

            it("should not wait") {
                expect(subject.should(wait: info, response: nil, with: nil, forRetryCompletion: { _ in })).to(beFalse())
            }

            it("should not verify") {
                expect({ try subject.verify(httpStatusCode: 123, header: [:], data: nil, error: nil) }).toNot(throwError())
            }
        }

        describe("overridden implementation of Plugin") {
            var subject: Plugin!
            var request: URLRequest!
            var info: PluginInfo!

            beforeEach {
                request = .testMake()
                info = .testMake(request: request)

                subject = OverriddenPlugin()
            }

            it("should prepare and modify request") {
                expect(subject.prepare(info)).toNot(equal(request))
            }

            it("should willSend") {
                subject.willSend(info)
                expect(subject).toNot(beNil())
            }

            it("should didFinish") {
                subject.didFinish(info, response: nil, with: nil, statusCode: nil)
                expect(subject).toNot(beNil())
            }

            it("should wait") {
                expect(subject.should(wait: info, response: nil, with: nil, forRetryCompletion: { _ in })).to(beTrue())
            }

            it("should verify and throw error") {
                expect({ try subject.verify(httpStatusCode: 123, header: [:], data: nil, error: nil) }).to(throwError(TestError.case1))
            }
        }
    }
}
