import Foundation
import UIKit

import Quick
import Nimble
import Spry
import Spry_Nimble

@testable import NRequest
@testable import NRequestTestHelpers
@testable import NCallback
@testable import NCallbackTestHelpers

class RequestFactorySpec: QuickSpec {
    private typealias Error = RequestError
    private struct TestInfo: Decodable { }

    override func spec() {
        describe("RequestFactory") {
            var subject: AnyRequestFactory<Error>!
            var originalFacroty: FakeRequestFactory<Error>!

            beforeEach {
                originalFacroty = .init()
                subject = originalFacroty.toAny()
            }

            it("should not wrap twice") {
                expect(subject.toAny()).to(be(subject))
            }

            describe("ignorable response") {
                var actualCallback: ResultCallback<Ignorable, Error>!
                var originalCallback: FakeResultCallback<Ignorable, Error>!
                var parameters: Parameters!

                beforeEach {
                    parameters = .testMake()
                    originalCallback = .init()
                    originalFacroty.stub(.request).andReturn(originalCallback)
                    actualCallback = subject.request(with: parameters)
                }

                it("should make request") {
                    expect(actualCallback).to(be(originalCallback))
                }

                it("should add required plugins") {
                    expect(originalFacroty).to(haveReceived(.request, with: parameters))
                }
            }

            describe("image response") {
                var actualCallback: ResultCallback<UIImage, Error>!
                var originalCallback: FakeResultCallback<UIImage, Error>!
                var parameters: Parameters!

                beforeEach {
                    parameters = .testMake()
                    originalCallback = .init()
                    originalFacroty.stub(.request).andReturn(originalCallback)
                    actualCallback = subject.request(with: parameters)
                }

                it("should make request") {
                    expect(actualCallback).to(be(originalCallback))
                }

                it("should add required plugins") {
                    expect(originalFacroty).to(haveReceived(.request, with: parameters))
                }
            }

            describe("decodable response") {
                var actualCallback: ResultCallback<TestInfo, Error>!
                var originalCallback: FakeResultCallback<TestInfo, Error>!
                var parameters: Parameters!

                beforeEach {
                    parameters = .testMake()
                    originalCallback = .init()
                    originalFacroty.stub(.request).andReturn(originalCallback)
                    actualCallback = subject.request(with: parameters)
                }

                it("should make request") {
                    expect(actualCallback).to(be(originalCallback))
                }

                it("should add required plugins") {
                    expect(originalFacroty).to(haveReceived(.request, with: parameters))
                }
            }

            describe("decodable response with Type as parameter (proxy method)") {
                var actualCallback: ResultCallback<TestInfo, Error>!
                var originalCallback: FakeResultCallback<TestInfo, Error>!
                var parameters: Parameters!

                beforeEach {
                    parameters = .testMake()
                    originalCallback = .init()
                    originalFacroty.stub(.request).andReturn(originalCallback)
                    actualCallback = subject.request(TestInfo.self, with: parameters)
                }

                it("should make request") {
                    expect(actualCallback).to(be(originalCallback))
                }

                it("should add required plugins") {
                    expect(originalFacroty).to(haveReceived(.request, with: parameters))
                }
            }

            describe("data response") {
                var actualCallback: ResultCallback<Data, Error>!
                var originalCallback: FakeResultCallback<Data, Error>!
                var parameters: Parameters!

                beforeEach {
                    parameters = .testMake()
                    originalCallback = .init()
                    originalFacroty.stub(.request).andReturn(originalCallback)
                    actualCallback = subject.request(with: parameters)
                }

                it("should make request") {
                    expect(actualCallback).to(be(originalCallback))
                }

                it("should add required plugins") {
                    expect(originalFacroty).to(haveReceived(.request, with: parameters))
                }
            }
        }
    }
}
