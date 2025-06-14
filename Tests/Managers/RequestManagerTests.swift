#if canImport(SpryMacroAvailable) && swift(>=6.0)
import Combine
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

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
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.host1),
                 header: .init([.testMake(key: "some", value: "value1"), .testMake(key: "some", value: "value2")]),
                 body: .encode(TestInfo(id: 1)),
                 delayInSeconds: nil)
            .store(in: &observers)
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.host2),
                 body: .encode(TestInfo(id: 2)),
                 delayInSeconds: Constant.stubbedTimeoutInSeconds)
            .store(in: &observers)
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.brokenHost),
                 statusCode: 400,
                 body: .encode(TestInfo(id: 2)),
                 delayInSeconds: Constant.stubbedTimeoutInSeconds)
            .store(in: &observers)
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.emptyHost),
                 statusCode: 204,
                 body: .empty,
                 delayInSeconds: Constant.stubbedTimeoutInSeconds)
            .store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_variants() {
        let subject = SmartRequestManager.create()
        XCTAssertNotNil(subject.void)
        XCTAssertNotNil(subject.decodable)
        XCTAssertNotNil(subject.data)
        XCTAssertNotNil(subject.dataOptional)
        XCTAssertNotNil(subject.image)
        XCTAssertNotNil(subject.imageOptional)
        XCTAssertNotNil(subject.json)
        XCTAssertNotNil(subject.jsonOptional)
    }

    func test_stubbing() {
        let expectation1 = expectation(description: "should receive response")
        let subject = SmartRequestManager.create()
        let response: UnsafeValue<TestInfo> = .init()
        subject
            .request(address: Constant.address1)
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation1.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectation1], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 1))

        let expectation2 = expectation(description: "should receive response")
        let expectationReverted = expectation(description: "should not receive response")
        expectationReverted.isInverted = true
        subject.request(address: Constant.address2,
                        parameters: .testMake())
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation2.fulfill()
                expectationReverted.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectationReverted], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation2], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertEqual(response.value, .init(id: 2))

        let expectation3 = expectation(description: "should receive response")
        let expectationReverted2 = expectation(description: "should not receive response")
        expectationReverted2.isInverted = true
        subject.request(address: Constant.emptyAddress,
                        parameters: .testMake())
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation3.fulfill()
                expectationReverted2.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectationReverted2], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation3], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertNil(response.value)

        // autoreleased
        let expectation4 = expectation(description: "should receive response")
        let expectationReverted3 = expectation(description: "should not receive response")
        expectationReverted3.isInverted = true
        subject.request(address: Constant.address2,
                        parameters: .testMake())
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation4.fulfill()
                expectationReverted3.fulfill()
            }
            .detach()
            .deferredStart()

        wait(for: [expectationReverted3], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation4], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertEqual(response.value, .init(id: 2))

        // released -> error
        let expectationReverted4 = expectation(description: "should not receive response")
        expectationReverted4.isInverted = true
        response.value = nil
        subject.request(address: Constant.address2,
                        parameters: .testMake())
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectationReverted4.fulfill()
            }
            // ---> not retained task will released and automaticaly stop the attached request
            // .detach()
            // .storing(in: &observers)
            .start()

        wait(for: [expectationReverted4], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        XCTAssertNil(response.value)
    }

    func test_plugins() {
        let pluginStatusCode = Plugins.StatusCode()

        let pluginForManager: FakePlugin = .init(id: 1, priority: 500)
        pluginForManager.stub(.prepareWithParameters_Userinfo_Request_Session).andReturn()
        pluginForManager.stub(.verifyWithParameters_Userinfo_Data).andReturn()
        pluginForManager.stub(.willSendWithParameters_Userinfo_Request_Session).andReturn()
        pluginForManager.stub(.didReceiveWithParameters_Userinfo_Request_Data).andReturn()
        pluginForManager.stub(.didFinishWithParameters_Userinfo_Data).andReturn()

        let pluginForParam: FakePlugin = .init(id: 2, priority: 0)
        pluginForParam.stub(.prepareWithParameters_Userinfo_Request_Session).andReturn()
        pluginForParam.stub(.verifyWithParameters_Userinfo_Data).andReturn()
        pluginForParam.stub(.willSendWithParameters_Userinfo_Request_Session).andReturn()
        pluginForParam.stub(.didReceiveWithParameters_Userinfo_Request_Data).andReturn()
        pluginForParam.stub(.didFinishWithParameters_Userinfo_Data).andReturn()

        let subject = SmartRequestManager.create(withPlugins: [pluginStatusCode, pluginStatusCode, pluginForManager, pluginStatusCode])

        let response: UnsafeValue<TestInfo> = .init()
        let expectation1 = expectation(description: "should receive response")
        subject.request(address: Constant.address1,
                        parameters: .init(plugins: [pluginForParam, pluginStatusCode, pluginForParam, pluginStatusCode],
                                          cacheSettings: .testMake()))
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation1.fulfill()
            }
            .detach()
            .deferredStart()

        wait(for: [expectation1], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 1))
        XCTAssertHaveReceived(pluginForManager, .prepareWithParameters_Userinfo_Request_Session, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .verifyWithParameters_Userinfo_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .willSendWithParameters_Userinfo_Request_Session, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didReceiveWithParameters_Userinfo_Request_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didFinishWithParameters_Userinfo_Data, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(pluginForParam, .prepareWithParameters_Userinfo_Request_Session, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .verifyWithParameters_Userinfo_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .willSendWithParameters_Userinfo_Request_Session, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didReceiveWithParameters_Userinfo_Request_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didFinishWithParameters_Userinfo_Data, countSpecifier: .exactly(1))

        pluginForManager.resetCalls()
        pluginForParam.resetCalls()

        let expectation2 = expectation(description: "should receive response")
        subject.request(address: Constant.address2,
                        parameters: .init(plugins: [pluginForParam]))
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation2.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectation2], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 2))

        let pluginValidator = Argument.validator { parameters in
            guard let parameters = parameters as? Parameters else {
                return false
            }

            let expected: [Plugin] = [pluginForParam, pluginStatusCode, pluginForManager]
            return parameters.plugins.map(\.id) == expected.map(\.id)
        }

        XCTAssertHaveReceived(pluginForManager, .prepareWithParameters_Userinfo_Request_Session, with: pluginValidator, Argument.anything, Argument.anything, Argument.anything, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .verifyWithParameters_Userinfo_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .willSendWithParameters_Userinfo_Request_Session, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didReceiveWithParameters_Userinfo_Request_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForManager, .didFinishWithParameters_Userinfo_Data, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(pluginForParam, .prepareWithParameters_Userinfo_Request_Session, with: pluginValidator, Argument.anything, Argument.anything, Argument.anything, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .verifyWithParameters_Userinfo_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .willSendWithParameters_Userinfo_Request_Session, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didReceiveWithParameters_Userinfo_Request_Data, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(pluginForParam, .didFinishWithParameters_Userinfo_Data, countSpecifier: .exactly(1))
    }

    func test_lack_parameters() {
        let expectation: XCTestExpectation = .init(description: "should receive response")
        let subject = SmartRequestManager.create()
        let result: UnsafeResult<TestInfo> = .init()
        subject
            .request(address: Constant.address1, parameters: .init(body: .encode(BrokenTestInfo(id: 1))))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), RequestEncodingError.invalidJSON)
    }

    func test_stop_the_line_verify_passOver() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()],
                                                 stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // passOver
        let expectation: XCTestExpectation = .init(description: "should receive response")
        stopTheLine.stub(.verifyWithResponse_Address_Parameters_Userinfo).andReturn(StopTheLineAction.passOver)
        subject.request(address: Constant.brokenAddress,
                        parameters: .init(body: .encode(TestInfo(id: 1))))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
    }

    func test_stop_the_line_and_skip_it() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()],
                                                 stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // passOver
        let expectation: XCTestExpectation = .init(description: "should receive response")
        stopTheLine.stub(.verifyWithResponse_Address_Parameters_Userinfo).andReturn(StopTheLineAction.stopTheLine)
        subject.request(address: Constant.brokenAddress, parameters: .init(shouldIgnoreStopTheLine: true))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
        XCTAssertHaveNotReceived(stopTheLine, .verifyWithResponse_Address_Parameters_Userinfo)
    }

    func test_stop_the_line_verify_retry() {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()], stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // retry
        let expectation1: XCTestExpectation = .init(description: "should not receive response")
        let expectation2: XCTestExpectation = .init(description: "should receive response")
        expectation1.isInverted = true
        stopTheLine.stubAgain(.verifyWithResponse_Address_Parameters_Userinfo).andReturn(StopTheLineAction.retry)
        let req = subject.request(address: Constant.brokenAddress, parameters: .init(body: .encode(TestInfo(id: 1))))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation1.fulfill()
                expectation2.fulfill()
            }

        req.start()
        wait(for: [expectation1], timeout: Constant.timeoutInSeconds)
        stopTheLine.stubAgain(.verifyWithResponse_Address_Parameters_Userinfo).andReturn(StopTheLineAction.passOver)

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
        stop_the_line(.passOver(.testMake(statusCode: StatusCode.Kind.badGateway.rawValue, error: StatusCode(.badGateway))), newCode: .badGateway)
    }

    private func stop_the_line(_ action: StopTheLineResult, newCode: StatusCode.Kind? = nil) {
        let stopTheLine: FakeStopTheLine = .init()
        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()],
                                                 stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // stopTheLine
        stopTheLine.resetCallsAndStubs()
        stopTheLine.stub(.actionWithWith_Response_Address_Parameters_Userinfo).andReturn(action)
        stopTheLine.stub(.verifyWithResponse_Address_Parameters_Userinfo).andDo { args in
            guard let result = args[0] as? SmartResponse else {
                fatalError()
            }

            if result.request?.url?.host == Constant.brokenHost {
                return StopTheLineAction.stopTheLine
            }
            return StopTheLineAction.passOver
        }

        let expectation3: XCTestExpectation = .init(description: "should receive response")
        subject.request(address: Constant.brokenAddress,
                        parameters: .init(body: .encode(TestInfo(id: 1))))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation3.fulfill()
            }
            .storing(in: &observers)
            .start()

        let expectation7: XCTestExpectation = .init(description: "should not receive response")
        expectation7.isInverted = true
        wait(for: [expectation7], timeout: Constant.stubbedTimeoutInSeconds)

        // waiter
        let expectation4: XCTestExpectation = .init(description: "should receive response")
        subject.request(address: Constant.address1,
                        parameters: .init(body: .empty))
            .decode(TestInfo.self)
            .complete { _ in
                expectation4.fulfill()
            }
            .detach()
            .deferredStart()

        // returns response immediately, but in queue while stop the line activated
        let expectation8: XCTestExpectation = .init(description: "should not receive response")
        expectation8.isInverted = true
        wait(for: [expectation8], timeout: Constant.stubbedTimeoutInSeconds)

        stopTheLine.resetCallsAndStubs()
        stopTheLine.stub(.actionWithWith_Response_Address_Parameters_Userinfo).andReturn(action)
        stopTheLine.stub(.verifyWithResponse_Address_Parameters_Userinfo).andReturn(StopTheLineAction.passOver)

        wait(for: [expectation3, expectation4], timeout: Constant.timeoutInSeconds * 3)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(newCode ?? .badRequest))
    }
}
#endif
