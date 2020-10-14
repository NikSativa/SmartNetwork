import Foundation

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class ResponseQueueSpec: QuickSpec {
    override func spec() {
        describe("ResponseQueue") {
            var subject: ResponseQueue!

            describe("fake queue") {
                describe("absent") {
                    beforeEach {
                        subject = .absent
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        it("should call task immediately") {
                            var didCall = false
                            subject.fire {
                                didCall = true
                            }
                            expect(didCall).to(beTrue())
                        }
                    }

                    context("when calling sync") {
                        it("should call task immediately") {
                            var didCall = false
                            subject.fire {
                                didCall = true
                            }
                            expect(didCall).to(beTrue())
                        }
                    }
                }

                describe("sync") {
                    var queue: FakeDispatchResponseQueue!

                    beforeEach {
                        queue = .init()
                        subject = .sync(queue)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        var didCall: Bool!

                        beforeEach {
                            didCall = false
                            queue.stub(.sync).andReturn()
                            subject.fire {
                                didCall = true
                            }
                        }

                        it("should schedule task") {
                            expect(didCall).to(beFalse())
                            expect(queue).to(haveReceived(.sync, with: Argument.anything, countSpecifier: .exactly(1)))
                        }

                        context("when the task is executed") {
                            beforeEach {
                                queue.syncWorkItem?()
                            }

                            it("should call task immediately") {
                                expect(didCall).to(beTrue())
                            }
                        }
                    }
                }

                describe("async") {
                    var queue: FakeDispatchResponseQueue!

                    beforeEach {
                        queue = .init()
                        subject = .async(queue)
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    context("when calling async") {
                        var didCall: Bool!

                        beforeEach {
                            didCall = false
                            queue.stub(.async).andReturn()
                            subject.fire {
                                didCall = true
                            }
                        }

                        it("should schedule task") {
                            expect(didCall).to(beFalse())
                            expect(queue).to(haveReceived(.async, with: Argument.anything, countSpecifier: .exactly(1)))
                        }

                        context("when the task is executed") {
                            beforeEach {
                                queue.asyncWorkItem?()
                            }

                            it("should call task immediately") {
                                expect(didCall).to(beTrue())
                            }
                        }
                    }
                }
            }

            describe("real queue") {
                describe("absent") {
                    beforeEach {
                        subject = .absent
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    it("should execute task immediately") {
                        var didCall = false
                        subject.fire {
                            sleep(1)
                            didCall = true
                        }
                        expect(didCall).to(beTrue())
                    }
                }

                describe("sync") {
                    beforeEach {
                        subject = .sync(DispatchQueue.global())
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    it("should execute task immediately") {
                        var didCall = false
                        subject.fire {
                            sleep(1)
                            didCall = true
                        }
                        expect(didCall).to(beTrue())
                    }
                }

                describe("async") {
                    beforeEach {
                        subject = .async(DispatchQueue.global())
                    }

                    it("should not be nil") {
                        expect(subject).toNot(beNil())
                    }

                    it("should schedule task") {
                        var didCall = false
                        subject.fire {
                            sleep(1)
                            didCall = true
                        }
                        expect(didCall).to(beFalse())
                        expect(didCall).toEventually(beTrue(), timeout: 2)
                    }
                }
            }
        }
    }
}
