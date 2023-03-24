import Foundation
import Nimble
import NSpry
import NSpry_Nimble
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestSpec: QuickSpec {
    override func spec() {
        describe("Request") {
            var subject: Requestable!
            var parameters: Parameters!
            var session: FakeSession!
            var urlRequestable: FakeURLRequestRepresentation!

            beforeEach {
                session = .init()
                parameters = .testMake(queue: .absent,
                                       session: session)

                urlRequestable = .init()
                urlRequestable.stub(.sdk).andReturn(URLRequest.testMake(url: "google.com"))

                subject = Request.create(with: parameters,
                                         urlRequestable: urlRequestable)
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

                    subject.completion = { data in
                        responses.append(data)
                    }
                    subject.start()
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
                        subject.start()
                    }

                    it("should cancel previous task and resume new") {
                        expect(task).to(haveReceived(.resume))
                        expect(task).to(haveReceived(.isRunning))
                        expect(task).to(haveReceived(.cancel))
                    }
                }

                context("when request completed") {
                    beforeEach {
                        task.stub(.isRunning).andReturn(false)
                        sessionCompletionHandler(nil, nil, nil)
                    }

                    it("should receive response") {
                        expect(responses).to(equal([.testMake(body: nil,
                                                              response: nil,
                                                              error: nil)]))
                    }

                    context("when request completed for the second time") {
                        beforeEach {
                            sessionCompletionHandler(nil, nil, nil)
                        }

                        it("should receive response") {
                            expect(responses).to(equal([
                                .testMake(body: nil,
                                          response: nil,
                                          error: nil),
                                .testMake(body: nil,
                                          response: nil,
                                          error: nil)
                            ]))
                        }
                    }
                }
            }
        }
    }
}
