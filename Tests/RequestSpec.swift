import Foundation
import UIKit

import Nimble
import NSpry
import NSpry_Nimble
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestSpec: QuickSpec {
    private enum Constant {
        static let userInfo: Parameters.UserInfo = ["key": 123]
    }

    override func spec() {
        describe("Request") {
            var subject: Request!
            var parameters: Parameters!
            var session: FakeSession!
            var pluginContext: FakePluginProvider!

            beforeEach {
                session = .init()
                pluginContext = .init()
                parameters = .testMake(queue: .absent,
                                       userInfo: Constant.userInfo,
                                       session: session)
                subject = Impl.Request(parameters: parameters,
                                       pluginContext: pluginContext)
            }

            it("should save parameters to var") {
                expect(subject.parameters) == parameters
            }

            describe("idle request") {
                describe("canceling") {
                    beforeEach {
                        subject.cancel()
                    }

                    it("should nothing happen") {
                        expect(true).to(beTrue())
                    }
                }

#if arch(x86_64) && canImport(Darwin)
                describe("restarting") {
                    it("should nothing happen") {
                        expect(subject.restartIfNeeded()).toNot(throwAssertion())
                    }
                }
#endif
            }

            describe("starting") {
                var responses: [ResponseData]!
                var task: FakeSessionTask!
                var sessionCompletionHandler: Session.CompletionHandler!

                beforeEach {
                    responses = []

                    task = .init()
                    task.stub(.resume).andReturn()

                    session.stub(.task).andDo { args in
                        sessionCompletionHandler = args[1] as? Session.CompletionHandler
                        return task
                    }

                    pluginContext.stub(.plugins).andReturn([])

                    subject.start { data in
                        responses.append(data)
                    }
                }

                afterEach {
                    sessionCompletionHandler = nil

                    // deinit
                    task.resetCallsAndStubs()
                    task.stub(.isRunning).andReturn(false)

                    subject = nil
                }

                it("should wait response") {
                    expect(responses).to(beEmpty())
                }

                it("should start session task") {
                    expect(task).to(haveReceived(.resume))
                }

                it("should take plugins") {
                    expect(pluginContext).to(haveReceived(.plugins))
                }

                describe("canceling") {
                    beforeEach {
                        task.resetCallsAndStubs()
                        task.stub(.isRunning).andReturn(true)
                        task.stub(.cancel).andReturn()
                        subject.cancel()
                    }

                    it("should cancel previous task") {
                        expect(task).to(haveReceived(.isRunning))
                        expect(task).to(haveReceived(.cancel))
                    }
                }

                describe("restarting") {
                    beforeEach {
                        task.resetCallsAndStubs()
                        task.stub(.resume).andReturn()
                        task.stub(.isRunning).andReturn(true)
                        task.stub(.cancel).andReturn()
                        subject.restartIfNeeded()
                    }

                    it("should cancel previous task and resume new") {
                        expect(task).to(haveReceived(.resume))
                        expect(task).to(haveReceived(.isRunning))
                        expect(task).to(haveReceived(.cancel))
                    }
                }

                context("when request completed") {
                    beforeEach {
                        sessionCompletionHandler(nil, nil, nil)
                    }

                    it("should receive response") {
                        expect(responses).to(equal([.testMake(body: nil,
                                                              response: nil,
                                                              error: nil,
                                                              userInfo: Constant.userInfo)]))
                    }

                    context("when request completed for the second time") {
                        beforeEach {
                            sessionCompletionHandler(nil, nil, nil)
                        }

                        it("should receive response") {
                            expect(responses).to(equal([.testMake(body: nil,
                                                                  response: nil,
                                                                  error: nil,
                                                                  userInfo: Constant.userInfo),
                                                        .testMake(body: nil,
                                                                  response: nil,
                                                                  error: nil,
                                                                  userInfo: Constant.userInfo)]))
                        }
                    }
                }
            }
        }
    }
}
