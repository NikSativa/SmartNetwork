import Combine
import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestManagerTests: XCTestCase {
    private enum Constant {
        static let host1 = "example1.com"
        static let address1: Address = .testMake(string: "http://example1.com/signin")

        static let host2 = "example2.com"
        static let address2: Address = .testMake(string: "http://example2.com/signin")
    }

    private typealias Error = RequestError

    private var observers: [AnyCancellable] = []

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isHost(Constant.host1),
                                  body: .encodable(TestInfo(id: 1))).store(in: &observers)
        HTTPStubServer.shared.add(condition: .isHost(Constant.host2),
                                  body: .encodable(TestInfo(id: 2)),
                                  delayInSeconds: 0.5).store(in: &observers)
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
                                 with: .init(address: Constant.address1)) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(response, .init(id: 1))

        expectation = .init(description: "should receive response")
        let expectationReverted: XCTestExpectation = .init(description: "should not receive response")
        expectationReverted.isInverted = true
        subject.requestDecodable(TestInfo.self,
                                 with: .init(address: Constant.address2)) {
            response = try? $0.get()
            expectation.fulfill()
            expectationReverted.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectationReverted], timeout: 0.48) // delayed response 0.5
        wait(for: [expectation], timeout: 0.52) // magic number = 1 - 0.48 = 0.52
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
                                 with: .init(address: Constant.address1,
                                             plugins: [requestPlugin],
                                             cacheSettings: .testMake())) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(response, .init(id: 1))
        XCTAssertHaveReceived(plugin, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(plugin, .verify, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(requestPlugin, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(requestPlugin, .didReceive, countSpecifier: .exactly(1))

        plugin.resetCalls()
        requestPlugin.resetCalls()

        expectation = .init(description: "should receive response")
        subject.requestDecodable(TestInfo.self,
                                 with: .init(address: Constant.address2,
                                             plugins: [requestPlugin])) {
            response = try? $0.get()
            expectation.fulfill()
        }.start().store(in: &observers)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(response, .init(id: 2))
        XCTAssertHaveReceived(plugin, .prepare, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(plugin, .verify, countSpecifier: .exactly(1))

        XCTAssertHaveReceived(requestPlugin, .willSend, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(requestPlugin, .didReceive, countSpecifier: .exactly(1))
    }
}
