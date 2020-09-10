import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class TokenStorageSpec: QuickSpec {
    private enum Constant {
        static let key = "unique key"
        static let value = "unique value"
    }

    override func spec() {
        describe("TokenStorage") {
            var subject: TokenStorage!
            var storage: FakeStorage!

            beforeEach {
                storage = .init()
                subject = Impl.TokenStorage(storage: storage,
                                            key: Constant.key)
            }

            context("when storage is empty") {
                var actual: String?

                beforeEach {
                    storage.stub(.tokenForKey).andReturn(nil)
                    actual = subject.token
                }

                it("should be nil") {
                    expect(actual).to(beNil())
                }

                it("should be empty") {
                    expect(subject.isEmpty).to(beTrue())
                }
            }

            context("when storage contains token") {
                var actual: String?

                beforeEach {
                    storage.stub(.tokenForKey).andReturn(Constant.value)
                    actual = subject.token
                }

                it("should be nil") {
                    expect(actual).to(equal(Constant.value))
                }

                it("should not be empty") {
                    expect(subject.isEmpty).toNot(beTrue())
                }
            }
        }
    }
}
