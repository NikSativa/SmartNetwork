import Foundation
import UIKit

import Nimble
import NSpry
import Quick

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestErrorSpec: QuickSpec {
    override func spec() {
        describe("RequestError") {
            describe("wrap") {
                it("should make generic") {
                    let actual: Error = NSError(domain: "111", code: 212, userInfo: nil)
                    let expected: RequestError = .generic(.init(actual))
                    expect(.wrap(actual)) == expected
                }

                it("should make connection") {
                    let actual = ConnectionError.cannotConnectToHost
                    let expected: RequestError = .connection(actual)
                    expect(.wrap(actual)) == expected
                }

                it("should make encoding") {
                    let actual = EncodingError.invalidJSON
                    let expected: RequestError = .encoding(actual)
                    expect(.wrap(actual)) == expected
                }

                it("should make decoding") {
                    let actual = DecodingError.brokenResponse
                    let expected: RequestError = .decoding(actual)
                    expect(.wrap(actual)) == expected
                }

                it("should make statusCode") {
                    let actual = StatusCode.forbidden
                    let expected: RequestError = .statusCode(actual)
                    expect(.wrap(actual)) == expected
                }
            }

            describe("init") {
                it("should make generic") {
                    let actual: Error = NSError(domain: "111", code: 212, userInfo: nil)
                    expect(RequestError(actual)).to(beNil())
                }

                it("should make connection") {
                    let actual = ConnectionError.cannotConnectToHost
                    let expected: RequestError = .connection(actual)
                    expect(RequestError(actual)) == expected
                }

                it("should make encoding") {
                    let actual = EncodingError.invalidJSON
                    let expected: RequestError = .encoding(actual)
                    expect(RequestError(actual)) == expected
                }

                it("should make decoding") {
                    let actual = DecodingError.brokenResponse
                    let expected: RequestError = .decoding(actual)
                    expect(RequestError(actual)) == expected
                }

                it("should make statusCode") {
                    let actual = StatusCode.forbidden
                    let expected: RequestError = .statusCode(actual)
                    expect(RequestError(actual)) == expected
                }
            }
        }
    }
}
