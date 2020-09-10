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

class BaseRequestFactorySpec: QuickSpec {
    private typealias Error = RequestError
    private struct TestInfo: Decodable { }

    override func spec() {
        describe("BaseRequestFactory") {
            var subject: BaseRequestFactory<Error>!

            describe("containing plugin provider") {
                var pluginProvider: FakePluginProvider!
                var plugin: FakePlugin!

                beforeEach {
                    plugin = .init()

                    pluginProvider = .init()
                    pluginProvider.stub(.plugins).andReturn([plugin])

                    subject = BaseRequestFactory(pluginProvider: pluginProvider)
                }

                describe("ignorable response") {
                    var actualCallback: ResultCallback<Ignorable, Error>!
                    var parameters: Parameters!

                    beforeEach {
                        parameters = .testMake()
                        actualCallback = subject.request(with: parameters)
                    }

                    it("should make request") {
                        expect(actualCallback).toNot(beNil())
                    }

                    it("should add required plugins") {
                        expect(pluginProvider).to(haveReceived(.plugins))
                    }
                }

                describe("image response") {
                    var actualCallback: ResultCallback<UIImage, Error>!
                    var parameters: Parameters!

                    beforeEach {
                        parameters = .testMake()
                        actualCallback = subject.request(with: parameters)
                    }

                    it("should make request") {
                        expect(actualCallback).toNot(beNil())
                    }

                    it("should add required plugins") {
                        expect(pluginProvider).to(haveReceived(.plugins))
                    }
                }

                describe("decodable response") {
                    var actualCallback: ResultCallback<TestInfo, Error>!
                    var parameters: Parameters!

                    beforeEach {
                        parameters = .testMake()
                        actualCallback = subject.request(with: parameters)
                    }

                    it("should make request") {
                        expect(actualCallback).toNot(beNil())
                    }

                    it("should add required plugins") {
                        expect(pluginProvider).to(haveReceived(.plugins))
                    }
                }

                describe("decodable response with Type as parameter (proxy method)") {
                    var actualCallback: ResultCallback<TestInfo, Error>!
                    var parameters: Parameters!

                    beforeEach {
                        parameters = .testMake()
                        actualCallback = subject.request(TestInfo.self, with: parameters)
                    }

                    it("should make request") {
                        expect(actualCallback).toNot(beNil())
                    }

                    it("should add required plugins") {
                        expect(pluginProvider).to(haveReceived(.plugins))
                    }
                }

                describe("data response") {
                    var actualCallback: ResultCallback<Data, Error>!
                    var parameters: Parameters!

                    beforeEach {
                        parameters = .testMake()
                        actualCallback = subject.request(with: parameters)
                    }

                    it("should make request") {
                        expect(actualCallback).toNot(beNil())
                    }

                    it("should add required plugins") {
                        expect(pluginProvider).to(haveReceived(.plugins))
                    }
                }
            }

            describe("data response; when plugin provider is absent") {
                var actualCallback: ResultCallback<Data, Error>!
                var parameters: Parameters!

                beforeEach {
                    subject = BaseRequestFactory(pluginProvider: nil)
                    parameters = .testMake()
                    actualCallback = subject.request(with: parameters)
                }

                it("should make request") {
                    expect(actualCallback).toNot(beNil())
                }
            }
        }
    }
}
