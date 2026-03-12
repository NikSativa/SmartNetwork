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
        static let url1: SmartURL = .testMake(string: "http://example1.com/signin")

        static let host2 = "example2.com"
        static let url2: SmartURL = .testMake(string: "http://example2.com/signin")

        static let brokenHost = "broken.com"
        static let brokenAddress: SmartURL = .testMake(string: "http://broken.com/signin")

        static let emptyHost = "empty.com"
        static let emptyAddress: SmartURL = .testMake(string: "http://empty.com/signin")
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
            .request(url: Constant.url1)
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
        subject.request(url: Constant.url2,
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
        subject.request(url: Constant.emptyAddress,
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
        subject.request(url: Constant.url2,
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
        subject.request(url: Constant.url2,
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

    func test_plugins() async {
        let pluginStatusCode = Plugins.StatusCode()

        let pluginForManager: FakePlugin = .init(id: 1, priority: 500)

        let pluginForParam: FakePlugin = .init(id: 2, priority: 0)

        let subject = SmartRequestManager.create(withPlugins: [pluginStatusCode, pluginStatusCode, pluginForManager, pluginStatusCode])

        let response: UnsafeValue<TestInfo> = .init()
        let expectation1 = expectation(description: "should receive response")
        subject.request(url: Constant.url1,
                        parameters: .init(plugins: [pluginForParam, pluginStatusCode, pluginForParam, pluginStatusCode],
                                          cacheSettings: .testMake()))
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation1.fulfill()
            }
            .detach()
            .deferredStart()

        await fulfillment(of: [expectation1], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 1))
        let managerPrepareCount = await pluginForManager.prepareCount
        let managerVerifyCount = await pluginForManager.verifyCount
        let managerWillSendCount = await pluginForManager.willSendCount
        let managerDidReceiveCount = await pluginForManager.didReceiveCount
        let managerDidFinishCount = await pluginForManager.didFinishCount
        XCTAssertEqual(managerPrepareCount, 1)
        XCTAssertEqual(managerVerifyCount, 1)
        XCTAssertEqual(managerWillSendCount, 1)
        XCTAssertEqual(managerDidReceiveCount, 1)
        XCTAssertEqual(managerDidFinishCount, 1)

        let paramPrepareCount = await pluginForParam.prepareCount
        let paramVerifyCount = await pluginForParam.verifyCount
        let paramWillSendCount = await pluginForParam.willSendCount
        let paramDidReceiveCount = await pluginForParam.didReceiveCount
        let paramDidFinishCount = await pluginForParam.didFinishCount
        XCTAssertEqual(paramPrepareCount, 1)
        XCTAssertEqual(paramVerifyCount, 1)
        XCTAssertEqual(paramWillSendCount, 1)
        XCTAssertEqual(paramDidReceiveCount, 1)
        XCTAssertEqual(paramDidFinishCount, 1)

        await pluginForManager.resetCalls()
        await pluginForParam.resetCalls()

        let expectation2 = expectation(description: "should receive response")
        subject.request(url: Constant.url2,
                        parameters: .init(plugins: [pluginForParam]))
            .decode(TestInfo.self)
            .complete {
                response.value = try? $0.get()
                expectation2.fulfill()
            }
            .storing(in: &observers)
            .start()

        await fulfillment(of: [expectation2], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response.value, .init(id: 2))
        let managerPrepareCount2 = await pluginForManager.prepareCount
        let managerVerifyCount2 = await pluginForManager.verifyCount
        let managerWillSendCount2 = await pluginForManager.willSendCount
        let managerDidReceiveCount2 = await pluginForManager.didReceiveCount
        let managerDidFinishCount2 = await pluginForManager.didFinishCount
        XCTAssertEqual(managerPrepareCount2, 1)
        XCTAssertEqual(managerVerifyCount2, 1)
        XCTAssertEqual(managerWillSendCount2, 1)
        XCTAssertEqual(managerDidReceiveCount2, 1)
        XCTAssertEqual(managerDidFinishCount2, 1)

        let paramPrepareCount2 = await pluginForParam.prepareCount
        let paramVerifyCount2 = await pluginForParam.verifyCount
        let paramWillSendCount2 = await pluginForParam.willSendCount
        let paramDidReceiveCount2 = await pluginForParam.didReceiveCount
        let paramDidFinishCount2 = await pluginForParam.didFinishCount
        XCTAssertEqual(paramPrepareCount2, 1)
        XCTAssertEqual(paramVerifyCount2, 1)
        XCTAssertEqual(paramWillSendCount2, 1)
        XCTAssertEqual(paramDidReceiveCount2, 1)
        XCTAssertEqual(paramDidFinishCount2, 1)

        let expectedPluginIDs = [pluginForParam.id, pluginStatusCode.id, pluginForManager.id]
        let managerPluginIDs = await pluginForManager.lastPreparedPluginIDs
        let paramPluginIDs = await pluginForParam.lastPreparedPluginIDs
        XCTAssertEqual(managerPluginIDs, expectedPluginIDs)
        XCTAssertEqual(paramPluginIDs, expectedPluginIDs)
    }

    func test_lack_parameters() {
        let expectation: XCTestExpectation = .init(description: "should receive response")
        let subject = SmartRequestManager.create()
        let result: UnsafeResult<TestInfo> = .init()
        subject
            .request(url: Constant.url1, parameters: .init(body: .encode(BrokenTestInfo(id: 1))))
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

    func test_stop_the_line_verify_passOver() async {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()],
                                                 stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // passOver
        let expectation: XCTestExpectation = .init(description: "should receive response")
        await stopTheLine.setVerifyResult(.passOver)
        subject.request(url: Constant.brokenAddress,
                        parameters: .init(body: .encode(TestInfo(id: 1))))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation.fulfill()
            }
            .storing(in: &observers)
            .start()

        await fulfillment(of: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
    }

    func test_stop_the_line_and_skip_it() async {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()],
                                                 stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // passOver
        let expectation: XCTestExpectation = .init(description: "should receive response")
        await stopTheLine.setVerifyResult(.stopTheLine)
        subject.request(url: Constant.brokenAddress, parameters: .init(shouldIgnoreStopTheLine: true))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation.fulfill()
            }
            .storing(in: &observers)
            .start()

        await fulfillment(of: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
        let verifyCount = await stopTheLine.verifyCount
        XCTAssertEqual(verifyCount, 0)
    }

    func test_stop_the_line_verify_retry() async {
        let stopTheLine: FakeStopTheLine = .init()

        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()], stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // retry
        let expectation1: XCTestExpectation = .init(description: "should not receive response")
        let expectation2: XCTestExpectation = .init(description: "should receive response")
        expectation1.isInverted = true
        await stopTheLine.setVerifyResult(.retry)
        let req = subject.request(url: Constant.brokenAddress, parameters: .init(body: .encode(TestInfo(id: 1))))
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation1.fulfill()
                expectation2.fulfill()
            }

        req.start()
        await fulfillment(of: [expectation1], timeout: Constant.timeoutInSeconds)
        await stopTheLine.setVerifyResult(.passOver)

        await fulfillment(of: [expectation2], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))
    }

    func test_stop_the_line_action_useOriginal() async {
        await stop_the_line(.useOriginal)
    }

    func test_stop_the_line_action_retry() async {
        await stop_the_line(.retry)
    }

    func test_stop_the_line_action_passOver() async {
        await stop_the_line(.passOver(.testMake(statusCode: StatusCode.Kind.badGateway.rawValue, error: StatusCode(.badGateway))), newCode: .badGateway)
    }

    func test_stop_the_line_action_uses_same_custom_session_for_internal_manager() {
        let tracker = SessionTracker()
        let session = FakeSmartURLSession()
        let pluginStatusCode = Plugins.StatusCode()
        let plugin: Plugin = SessionCapturePlugin(priority: -100) { session in
            tracker.append(session)
        }

        let stopTheLine = SessionAwareStopTheLine { manager in
            _ = await manager.request(url: Constant.url1,
                                      parameters: .init(shouldIgnoreStopTheLine: true),
                                      userInfo: .init())
            return .useOriginal
        }

        let subject = SmartRequestManager.create(withPlugins: [pluginStatusCode, plugin],
                                                 stopTheLine: stopTheLine,
                                                 session: session)

        let expectation = expectation(description: "should receive response")
        let result: UnsafeResult<TestInfo> = .init()
        subject.request(url: Constant.brokenAddress)
            .decode(TestInfo.self)
            .complete {
                result.value = $0
                expectation.fulfill()
            }
            .storing(in: &observers)
            .start()

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(.badRequest))

        let expectedIdentity = ObjectIdentifier(session)
        let identities = tracker.ids
        XCTAssertGreaterThanOrEqual(identities.count, 2)
        XCTAssertTrue(identities.allSatisfy { $0 == expectedIdentity })
    }

    private func stop_the_line(_ action: StopTheLineResult, newCode: StatusCode.Kind? = nil) async {
        let stopTheLine: FakeStopTheLine = .init()
        let subject = SmartRequestManager.create(withPlugins: [Plugins.StatusCode()],
                                                 stopTheLine: stopTheLine)
        let result: UnsafeResult<TestInfo> = .init()

        // stopTheLine
        await stopTheLine.reset()
        await stopTheLine.setActionResult(action)
        await stopTheLine.setVerifyHandler { response, _, _, _ in
            if response.request?.url?.host == Constant.brokenHost {
                return .stopTheLine
            }
            return .passOver
        }

        let expectation3: XCTestExpectation = .init(description: "should receive response")
        subject.request(url: Constant.brokenAddress,
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
        await fulfillment(of: [expectation7], timeout: Constant.stubbedTimeoutInSeconds)

        // waiter
        let expectation4: XCTestExpectation = .init(description: "should receive response")
        subject.request(url: Constant.url1,
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
        await fulfillment(of: [expectation8], timeout: Constant.stubbedTimeoutInSeconds)

        await stopTheLine.reset()
        await stopTheLine.setActionResult(action)
        await stopTheLine.setVerifyResult(.passOver)

        await fulfillment(of: [expectation3, expectation4], timeout: Constant.timeoutInSeconds * 3)
        XCTAssertThrowsError(try result.value?.get(), StatusCode(newCode ?? .badRequest))
    }
}

private final class SessionTracker: @unchecked Sendable {
    @AtomicValue
    private var values: [ObjectIdentifier] = []

    var ids: [ObjectIdentifier] {
        return $values.syncUnchecked { $0 }
    }

    func append(_ session: SmartURLSession) {
        let id = ObjectIdentifier(session as AnyObject)
        $values.syncUnchecked { $0.append(id) }
    }
}

private actor SessionCapturePlugin: Plugin {
    nonisolated let id: ID
    nonisolated let priority: PluginPriority

    #if swift(>=6.0)
    typealias PrepareClosure = @Sendable (SmartURLSession) -> Void
    #else
    typealias PrepareClosure = (SmartURLSession) -> Void
    #endif
    private let onPrepare: PrepareClosure

    init(id: ID = UUID().uuidString,
         priority: PluginPriority,
         onPrepare: @escaping PrepareClosure) {
        self.id = id
        self.priority = priority
        self.onPrepare = onPrepare
    }

    func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async throws {
        onPrepare(session)
    }

    func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {}
    func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, response: SmartResponse) {}
    func verify(parameters: Parameters, userInfo: UserInfo, response: SmartResponse) async throws {}
    func didFinish(parameters: Parameters, userInfo: UserInfo, response: SmartResponse) {}
}

private actor SessionAwareStopTheLine: StopTheLine {
    #if swift(>=6.0)
    typealias ActionBlock = @Sendable (SmartRequestManager) async throws -> StopTheLineResult
    #else
    typealias ActionBlock = (SmartRequestManager) async throws -> StopTheLineResult
    #endif
    private let actionBlock: ActionBlock

    init(actionBlock: @escaping ActionBlock) {
        self.actionBlock = actionBlock
    }

    func verify(response: SmartResponse,
                url: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) -> StopTheLineAction {
        return response.request?.url?.host == "broken.com" ? .stopTheLine : .passOver
    }

    func action(with manager: SmartRequestManager,
                response: SmartResponse,
                url: SmartURL,
                parameters: Parameters,
                userInfo: UserInfo) async throws -> StopTheLineResult {
        return try await actionBlock(manager)
    }
}
#endif
