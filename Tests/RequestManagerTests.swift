import Combine
import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestManagerTests: XCTestCase {
    private enum Constant {
        static let timeoutInSeconds: TimeInterval = 0.5
        static let stubbedTimeoutInSeconds: TimeInterval = 0.2

        static let host1 = "example1.com"
        static let address1: Address = .testMake(string: "http://example1.com/signin")

        static let host2 = "example2.com"
        static let address2: Address = .testMake(string: "http://example2.com/signin")
    }

    private var observers: [AnyCancellable] = []

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isHost(Constant.host1),
                                  body: .encodable(TestInfo(id: 1))).store(in: &observers)
        HTTPStubServer.shared.add(condition: .isHost(Constant.host2),
                                  body: .encodable(TestInfo(id: 2)),
                                  delayInSeconds: Constant.stubbedTimeoutInSeconds).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_stubbing() {
        var expectation: XCTestExpectation = .init(description: "should receive response")
        let subject = RequestManager.create()
        var response: TestInfo?
        subject.requestDecodable(TestInfo.self,
                                 address: Constant.address1,
                                 with: .init()) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response, .init(id: 1))

        expectation = .init(description: "should receive response")
        let expectationReverted: XCTestExpectation = .init(description: "should not receive response")
        expectationReverted.isInverted = true
        subject.requestDecodable(TestInfo.self,
                                 address: Constant.address2,
                                 with: .testMake()) {
            response = try? $0.get()
            expectation.fulfill()
            expectationReverted.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectationReverted], timeout: Constant.stubbedTimeoutInSeconds - 0.01)
        wait(for: [expectation], timeout: Constant.timeoutInSeconds - Constant.stubbedTimeoutInSeconds + 0.01)
        XCTAssertEqual(response, .init(id: 2))
    }

    func test_plugins() {
        let plugin: FakePlugin = .init()
        plugin.stub(.prepare).andReturn()
        plugin.stub(.verify).andReturn()

        let requestPlugin: FakeRequestStatePlugin = .init()
        requestPlugin.stub(.willSend).andReturn()
        requestPlugin.stub(.didReceive).andReturn()

        let pluginProvider = PluginProvider.create(plugins: [Plugins.StatusCode(), plugin])
        let subject = RequestManager.create(withPluginProvider: pluginProvider)

        var response: TestInfo?
        var expectation: XCTestExpectation = .init(description: "should receive response")
        subject.requestDecodable(TestInfo.self,
                                 address: Constant.address1,
                                 with: .init(plugins: [requestPlugin],
                                             cacheSettings: .testMake())) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response, .init(id: 1))
        XCTAssertHaveReceived(plugin, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(plugin, .verify, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(requestPlugin, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(requestPlugin, .didReceive, countSpecifier: .exactly(1))

        plugin.resetCalls()
        requestPlugin.resetCalls()

        expectation = .init(description: "should receive response")
        subject.requestDecodable(TestInfo.self,
                                 address: Constant.address2,
                                 with: .init(plugins: [requestPlugin])) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertEqual(response, .init(id: 2))
        XCTAssertHaveReceived(plugin, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(plugin, .verify, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(requestPlugin, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(requestPlugin, .didReceive, countSpecifier: .exactly(1))
    }

    func test_lack_parameters() {
        let expectation: XCTestExpectation = .init(description: "should receive response")
        let subject = RequestManager.create()
        var result: Result<TestInfo, Error>?
        subject.requestDecodable(TestInfo.self,
                                 address: Constant.address1,
                                 with: .init(body: .encodable(BrokenTestInfo(id: 1)))) {
            result = $0
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: Constant.timeoutInSeconds)
        XCTAssertThrowsError(try result?.get(), RequestEncodingError.invalidJSON)
    }
}
