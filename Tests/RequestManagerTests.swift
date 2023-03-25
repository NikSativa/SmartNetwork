import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestManagerTests: XCTestCase {
    private typealias Error = RequestError
    private struct TestInfo: Decodable {}

    func test_request() {
        let subject = RequestManager.create(withPluginProvider: nil,
                                            stopTheLine: nil)
    }
}

// final class RequestManagerSpec: QuickSpec {
//    private typealias Error = RequestError
//    private struct TestInfo: Decodable {}
//
//    override func spec() {
//        describe("RequestManager") {
//            var subject: AnyRequestManager<Error>!
//            var factory: FakeRequestFactory!
//            var stubResponse: ((ResponseData) -> Void)!
//
//            beforeEach {
//                factory = .init()
//
//                stubResponse = { data in
//                    factory.stub(.make).andDo { args in
//                        let request = FakeRequest()
//                        request.stub(.start).andDo { args in
//                            let callback = args[0] as! Request.CompletionCallback
//                            callback(data)
//                            return ()
//                        }
//                        request.stub(.cancel).andReturn()
//                        return request
//                    }
//                }
//            }
//
//            describe("containing plugin provider") {
//                var pluginProvider: FakePluginProvider!
//                var factoryArgument: Argument!
//
//                beforeEach {
//                    pluginProvider = .init()
//                    factoryArgument = Argument.validator {
//                        return pluginProvider === ($0 as AnyObject)
//                    }
//
//                    subject = Impl.RequestManager(factory: factory,
//                                                  pluginProvider: pluginProvider,
//                                                  stopTheLine: nil).toAny()
//                }
//
//                describe("void response") {
//                    var actualCallback: ResultCallback<Void, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.requestVoid(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("image response") {
//                    var actualCallback: ResultCallback<Image, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.requestImage(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("optional image response") {
//                    var actualCallback: ResultCallback<Image?, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.requestOptionalImage(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("decodable response") {
//                    var actualCallback: ResultCallback<TestInfo, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.request(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("optional decodable response") {
//                    var actualCallback: ResultCallback<TestInfo?, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.request(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("decodable response with Type as parameter (proxy method)") {
//                    var actualCallback: ResultCallback<TestInfo, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.requestDecodable(TestInfo.self, with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("data response") {
//                    var actualCallback: ResultCallback<Data, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.request(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("optional data response") {
//                    var actualCallback: ResultCallback<Data?, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.request(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("any response") {
//                    var actualCallback: ResultCallback<Any, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.requestAny(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//
//                describe("optional any response") {
//                    var actualCallback: ResultCallback<Any?, Error>!
//                    var parameters: Parameters!
//
//                    beforeEach {
//                        parameters = .testMake()
//                        stubResponse(.testMake())
//                        actualCallback = subject.requestOptionalAny(with: parameters)
//                    }
//
//                    it("should make request") {
//                        expect(actualCallback).toNot(beNil())
//                        expect(factory).to(haveReceived(.make, with: parameters, factoryArgument))
//                    }
//                }
//            }
//
//            describe("data response; when plugin provider is absent") {
//                var actualCallback: ResultCallback<Data, Error>!
//                var parameters: Parameters!
//
//                beforeEach {
//                    subject = Impl.RequestManager(factory: factory,
//                                                  pluginProvider: nil,
//                                                  stopTheLine: nil).toAny()
//                    parameters = .testMake()
//                    stubResponse(.testMake())
//                    actualCallback = subject.request(with: parameters)
//                }
//
//                it("should make request") {
//                    expect(actualCallback).toNot(beNil())
//                }
//            }
//        }
//    }
// }
