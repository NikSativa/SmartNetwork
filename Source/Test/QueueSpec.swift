import Foundation

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest

class QueueSpec: QuickSpec {
    override func spec() {
        describe("Queue") {
            var subject: ResponseQueue!

            beforeEach {
                subject = DispatchQueue.main
            }

            it("should not be nil") {
                expect(subject).toNot(beNil())
            }

            describe("async") {
                var didCall = false
                beforeEach {
                    subject.async {
                        didCall = true
                    }
                }

                it("should call task") {
                    expect(didCall).toEventually(beTrue())
                }
            }
        }
    }
}
