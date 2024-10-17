import Combine
import Foundation
import SpryKit
import Threading
import XCTest

@testable import SmartNetwork

final class RequestManagerTests: XCTestCase {
    private enum Constant {
        static let timeoutInSeconds: TimeInterval = 2
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
        XCTAssertNotNil(subject.data)
        XCTAssertNotNil(subject.image)
        XCTAssertNotNil(subject.imageOptional)
        XCTAssertNotNil(subject.dataOptional)
        XCTAssertNotNil(subject.json)
        XCTAssertNotNil(subject.jsonOptional)
    }

    func test_stubbing() {
        let expectation1 = expectation(description: "should receive response")
        let subject = RequestManager.create()
        let response: SendableResult<TestInfo> = .init()
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init()) {
            response.value = try? $0.get()
            expectation1.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectation1], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 1))

        let expectation2 = expectation(description: "should receive response")
        let expectationReverted = expectation(description: "should not receive response")
        expectationReverted.isInverted = true
        subject.decodable.request(opt: TestInfo.self,
                                  address: Constant.address2,
                                  with: .testMake()) {
            response.value = try? $0.get()
            expectation2.fulfill()
            expectationReverted.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectationReverted], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation2], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertEqual(response.value, .init(id: 2))

        let expectation3 = expectation(description: "should receive response")
        let expectationReverted2 = expectation(description: "should not receive response")
        expectationReverted2.isInverted = true
        subject.decodable.request(TestInfo.self,
                                  address: Constant.emptyAddress,
                                  with: .testMake()) {
            response.value = try? $0.get()
            expectation3.fulfill()
            expectationReverted2.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectationReverted2], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation3], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertNil(response.value)

        // autoreleased
        let expectation4 = expectation(description: "should receive response")
        let expectationReverted3 = expectation(description: "should not receive response")
        expectationReverted3.isInverted = true
        subject.decodable.request(opt: TestInfo.self,
                                  address: Constant.address2,
                                  with: .testMake()) {
            response.value = try? $0.get()
            expectation4.fulfill()
            expectationReverted3.fulfill()
        }.autorelease().start()

        wait(for: [expectationReverted3], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation4], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertEqual(response.value, .init(id: 2))

        // released -> error
        let expectationReverted4 = expectation(description: "should not receive response")
        expectationReverted4.isInverted = true
        response.value = nil
        subject.decodable.request(opt: TestInfo.self,
                                  address: Constant.address2,
                                  with: .testMake()) {
            response.value = try? $0.get()
            expectationReverted4.fulfill()
        }
        // ---> not retained task will released and automaticaly stop the attached request
        // .autorelease()
        // .storing(in: &observers)
        .start()

        wait(for: [expectationReverted4], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        XCTAssertNil(response.value)
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

        let response: SendableResult<TestInfo> = .init()
        let expectation1 = expectation(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init(plugins: [pluginForParam],
                                              cacheSettings: .testMake())) {
            response.value = try? $0.get()
            expectation1.fulfill()
        }.autorelease().start()

        wait(for: [expectation1], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 1))
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

        let expectation2 = expectation(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address2,
                                  with: .init(plugins: [pluginForParam])) {
            response.value = try? $0.get()
            expectation2.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectation2], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 2))
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
        let result: SendableResult<Result<TestInfo, Error>> = .init()
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init(body: .encodable(BrokenTestInfo(id: 1)))) {
            result.value = $0
            expectation.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), RequestEncodingError.invalidJSON)
    }

    func test_stop_the_line_verify_passOver() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = RequestManager.create(withPlugins: [Plugins.StatusCode()],
                                            stopTheLine: stopTheLine,
                                            maxAttemptNumber: 1)
        let result: SendableResult<Result<TestInfo, Error>> = .init()

        // passOver
        let expectation: XCTestExpectation = .init(description: "should receive response")
        stopTheLine.stub(.verify).andReturn(StopTheLineAction.passOver)
        subject.decodable.request(TestInfo.self,
                                  address: Constant.brokenAddress,
                                  with: .init(body: .init(TestInfo(id: 1)))) {
            result.value = $0
            expectation.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
    }

    func test_stop_the_line_verify_retry() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = RequestManager.create(withPlugins: [Plugins.StatusCode()],
                                            stopTheLine: stopTheLine,
                                            maxAttemptNumber: 1)
        let result: SendableResult<Result<TestInfo, Error>> = .init()

        // retry (maxAttemptNumber: 1)
        let expectation2: XCTestExpectation = .init(description: "should receive response")
        stopTheLine.stubAgain(.verify).andReturn(StopTheLineAction.retry)
        subject.decodable.request(TestInfo.self,
                                  address: Constant.brokenAddress,
                                  with: .init(body: .init(TestInfo(id: 1)))) {
            result.value = $0
            expectation2.fulfill()
        }.storing(in: &observers).start()

        wait(for: [expectation2], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
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
        let result: SendableResult<Result<TestInfo, Error>> = .init()

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
            result.value = $0
            expectation3.fulfill()
        }.storing(in: &observers).start()

        let expectation7: XCTestExpectation = .init(description: "should not receive response")
        expectation7.isInverted = true
        wait(for: [expectation7], timeout: Constant.stubbedTimeoutInSeconds)

        // waiter
        let expectation4: XCTestExpectation = .init(description: "should receive response")
        subject.decodable.request(TestInfo.self,
                                  address: Constant.address1,
                                  with: .init(body: .empty)) { _ in
            expectation4.fulfill()
        }.autorelease().start()

        // returns response immediately, but in queue while stop the line activated
        let expectation8: XCTestExpectation = .init(description: "should not receive response")
        expectation8.isInverted = true
        wait(for: [expectation8], timeout: Constant.stubbedTimeoutInSeconds)

        stopTheLine.resetCallsAndStubs()
        stopTheLine.stub(.verify).andReturn(StopTheLineAction.passOver)
        stopTheLine.completion?(action)

        wait(for: [expectation3, expectation4], timeout: Constant.timeoutInSeconds * 3)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(newCode ?? .badRequest))
    }
}
