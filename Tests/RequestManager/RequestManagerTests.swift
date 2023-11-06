import Combine
import Foundation
import NQueue
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestManagerTests: XCTestCase {
    private enum Constant {
        static let timeoutInSeconds: TimeInterval = 0.5
        static let stubbedTimeoutInSeconds: TimeInterval = 0.2

        /// requirement: returns response immediately
        static let host1 = "example1.com"
        static let address1: Address = .testMake(string: "http://example1.com/signin")

        static let host2 = "example2.com"
        static let address2: Address = .testMake(string: "http://example2.com/signin")

        static let brokenHost = "broken.com"
        static let brokenAddress: Address = .testMake(string: "http://broken.com/signin")

        static let emptyHost = "empty.com"
        static let emptyAddress: Address = .testMake(string: "http://empty.com/signin")
    }

    private var observers: [AnyCancellable] = []

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isHost(Constant.host1),
                                  body: .encodable(TestInfo(id: 1)),
                                  delayInSeconds: nil).store(in: &observers)
        HTTPStubServer.shared.add(condition: .isHost(Constant.host2),
                                  body: .encodable(TestInfo(id: 2)),
                                  delayInSeconds: Constant.stubbedTimeoutInSeconds).store(in: &observers)
        HTTPStubServer.shared.add(condition: .isHost(Constant.brokenHost),
                                  statusCode: 400,
                                  body: .encodable(TestInfo(id: 2)),
                                  delayInSeconds: Constant.stubbedTimeoutInSeconds).store(in: &observers)
        HTTPStubServer.shared.add(condition: .isHost(Constant.emptyHost),
                                  statusCode: 204,
                                  body: .empty,
                                  delayInSeconds: Constant.stubbedTimeoutInSeconds).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_variants() {
        let subject = RequestManager.create()
        XCTAssertNotNil(subject.pure)
        XCTAssertNotNil(subject.void)
        XCTAssertNotNil(subject.decodable)
        XCTAssertNotNil(subject.image)
        XCTAssertNotNil(subject.imageOptional)
        XCTAssertNotNil(subject.data)
        XCTAssertNotNil(subject.dataOptional)
        XCTAssertNotNil(subject.json)
        XCTAssertNotNil(subject.jsonOptional)
    }

    func test_stubbing() {
        var expectation: XCTestExpectation = .init(description: "should receive response")
        let subject = RequestManager.create()
        var response: TestInfo?
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init()) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response, .init(id: 1))

        expectation = .init(description: "should receive response")
        var expectationReverted: XCTestExpectation = .init(description: "should not receive response")
        expectationReverted.isInverted = true
        subject.decodable.request(opt: TestInfo.self,
                                  address: Constant.address2,
                                  with: .testMake()) {
            response = try? $0.get()
            expectation.fulfill()
            expectationReverted.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectationReverted], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertEqual(response, .init(id: 2))

        expectation = .init(description: "should receive response")
        expectationReverted = .init(description: "should not receive response")
        expectationReverted.isInverted = true
        subject.decodable.request(TestInfo.self,
                                  address: Constant.emptyAddress,
                                  with: .testMake()) {
            response = try? $0.get()
            expectation.fulfill()
            expectationReverted.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectationReverted], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertNil(response)
    }

    func test_plugins() {
        let pluginForManager: FakePlugin = .init(id: 1)
        pluginForManager.stub(.prepare).andReturn()
        pluginForManager.stub(.verify).andReturn()
        pluginForManager.stub(.willSend).andReturn()
        pluginForManager.stub(.didReceive).andReturn()
        pluginForManager.stub(.didFinish).andReturn()

        let pluginForParam: FakePlugin = .init(id: 2)
        pluginForParam.stub(.prepare).andReturn()
        pluginForParam.stub(.verify).andReturn()
        pluginForParam.stub(.willSend).andReturn()
        pluginForParam.stub(.didReceive).andReturn()
        pluginForParam.stub(.didFinish).andReturn()

        let subject = RequestManager.create(withPlugins: [Plugins.StatusCode(), pluginForManager])

        var response: TestInfo?
        var expectation: XCTestExpectation = .init(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init(plugins: [pluginForParam],
                                              cacheSettings: .testMake())) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response, .init(id: 1))
        XCTAssertHaveReceived(pluginForManager, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .verify, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didReceive, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didFinish, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(pluginForParam, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .verify, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didReceive, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didFinish, countSpecifier: .exactly(1))

        pluginForManager.resetCalls()
        pluginForParam.resetCalls()

        expectation = .init(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address2,
                                  with: .init(plugins: [pluginForParam])) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response, .init(id: 2))
        XCTAssertHaveReceived(pluginForManager, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .verify, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didReceive, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didFinish, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(pluginForParam, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .verify, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didReceive, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didFinish, countSpecifier: .exactly(1))
    }

    func test_lack_parameters() {
        let expectation: XCTestExpectation = .init(description: "should receive response")
        let subject = RequestManager.create()
        var result: Result<TestInfo, Error>?
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init(body: .encodable(BrokenTestInfo(id: 1)))) {
            result = $0
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result?.get(), RequestEncodingError.invalidJSON)
    }

    func test_stop_the_line_verify_passOver() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = RequestManager.create(withPlugins: [Plugins.StatusCode()],
                                            stopTheLine: stopTheLine,
                                            maxAttemptNumber: 1)
        var result: Result<TestInfo, Error>?

        // passOver
        let expectation: XCTestExpectation = .init(description: "should receive response")
        stopTheLine.stub(.verify).andReturn(StopTheLineAction.passOver)
        subject.decodable.request(TestInfo.self,
                                  address: Constant.brokenAddress,
                                  with: .init(body: .init(TestInfo(id: 1)))) {
            result = $0
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result?.get(), StatusCode(.badRequest))
    }

    func test_stop_the_line_verify_retry() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = RequestManager.create(withPlugins: [Plugins.StatusCode()],
                                            stopTheLine: stopTheLine,
                                            maxAttemptNumber: 1)
        var result: Result<TestInfo, Error>?

        // retry (maxAttemptNumber: 1)
        let expectation2: XCTestExpectation = .init(description: "should receive response")
        stopTheLine.stubAgain(.verify).andReturn(StopTheLineAction.retry)
        subject.decodable.request(TestInfo.self,
                                  address: Constant.brokenAddress,
                                  with: .init(body: .init(TestInfo(id: 1)))) {
            result = $0
            expectation2.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation2], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result?.get(), StatusCode(.badRequest))
    }

    func test_stop_the_line_action_useOriginal() {
        stop_the_line(.useOriginal)
    }

    func test_stop_the_line_action_retry() {
        stop_the_line(.retry)
    }

    func test_stop_the_line_action_passOver() {
        stop_the_line(.passOver(.testMake(statusCode: StatusCode.Kind.badGateway.rawValue)),
                      newCode: .badGateway)
    }

    private func stop_the_line(_ action: StopTheLineResult, newCode: StatusCode.Kind? = nil) {
        let stopTheLine: FakeStopTheLine = .init()
        let subject = RequestManager.create(withPlugins: [Plugins.StatusCode()],
                                            stopTheLine: stopTheLine,
                                            maxAttemptNumber: 1)
        var result: Result<TestInfo, Error>?

        // stopTheLine
        stopTheLine.resetCallsAndStubs()
        stopTheLine.stub(.action).andReturn()
        stopTheLine.stub(.verify).andDo { args in
            guard let result = args[0] as? RequestResult else {
                fatalError()
            }
            if result.request?.url?.host == Constant.brokenHost {
                return StopTheLineAction.stopTheLine
            }
            return StopTheLineAction.passOver
        }

        let expectation3: XCTestExpectation = .init(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.brokenAddress,
                                  with: .init(body: .init(TestInfo(id: 1)))) {
            result = $0
            expectation3.fulfill()
        }.start().store(in: &observers)

        let expectation7: XCTestExpectation = .init(description: "should not receive response")
        expectation7.isInverted = true
        wait(for: [expectation7], timeout: Constant.stubbedTimeoutInSeconds)

        // waiter
        let expectation4: XCTestExpectation = .init(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init(body: .empty)) { _ in
            expectation4.fulfill()
        }.start().store(in: &observers)

        // returns response immediately, but in queue while stop the line activated
        let expectation8: XCTestExpectation = .init(description: "should not receive response")
        expectation8.isInverted = true
        wait(for: [expectation8], timeout: Constant.stubbedTimeoutInSeconds)

        stopTheLine.resetCallsAndStubs()
        stopTheLine.stub(.verify).andReturn(StopTheLineAction.passOver)
        stopTheLine.completion?(action)

        wait(for: [expectation3, expectation4], timeout: Constant.timeoutInSeconds * 3)
        XCTAssertThrowsError(try result?.get(), StatusCode(newCode ?? .badRequest))
    }
}
