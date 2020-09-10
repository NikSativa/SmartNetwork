import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers

class MutatedTokenStorageSpec: QuickSpec {
    private enum Constant {
        static let key = "unique key"
        static let value = "unique value"
    }

    override func spec() {
        describe("MutatedTokenStorage") {
            var subject: MutatedTokenStorage!
            var storage: FakeStorage!

            beforeEach {
                storage = .init()
                subject = Impl.TokenStorage(storage: storage,
                                            key: Constant.key)
            }

            describe("TokenStorage") {
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

            describe("mutating") {
                describe("set token") {
                    beforeEach {
                        storage.stub(.saveToken).andReturn()
                        subject.set(Constant.value)
                    }

                    it("should save token in storage") {
                        expect(storage).to(haveReceived(.saveToken, with: Constant.value, Constant.key))
                    }
                }

                describe("clear token") {
                    beforeEach {
                        storage.stub(.removeToken).andReturn()
                        subject.clear()
                    }

                    it("should save token in storage") {
                        expect(storage).to(haveReceived(.removeToken, with: Constant.key))
                    }
                }
            }
        }
    }
}
