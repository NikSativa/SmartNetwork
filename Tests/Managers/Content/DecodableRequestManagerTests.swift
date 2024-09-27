import Combine
import Foundation
import SmartNetwork
import XCTest

final class DecodableRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: [AnyCancellable] = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let subjset = RequestManager.create().decodable
    private let info = TestInfo(id: 1)

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isAddress(address),
                                  body: .encodable(info),
                                  delayInSeconds: stubbedTimeoutInSeconds).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_api_any() {
        let actual: SendableResult<TestInfo> = .init()
        let exp = expectation(description: #function)
        subjset.request(TestInfo.self,
                        address: address) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)
    }

    func test_api_main() {
        let actual: SendableResult<TestInfo> = .init()
        let exp = expectation(description: #function)
        subjset.request(TestInfo.self,
                        address: address,
                        with: .testMake(),
                        inQueue: .absent) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)
    }

    func test_api_main_opt() {
        let actual: SendableResult<TestInfo> = .init()
        let exp = expectation(description: #function)
        subjset.request(opt: TestInfo.self,
                        address: address,
                        with: .testMake(),
                        inQueue: .absent) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)
    }

    func test_api_async() async {
        var actual: TestInfo?
        let result = await subjset.request(TestInfo.self,
                                           address: address,
                                           with: .testMake())
        actual = try? result.get()
        XCTAssertEqual(info, actual)
    }

    func test_api_async_opt() async {
        var actual: TestInfo?
        let result = await subjset.request(opt: TestInfo.self,
                                           address: address,
                                           with: .testMake())
        actual = try? result.get()
        XCTAssertEqual(info, actual)
    }

    func test_api_async_throw() async throws {
        let result = try await subjset.requestWithThrowing(TestInfo.self,
                                                           address: address,
                                                           with: .testMake())
        XCTAssertEqual(info, result)
    }

    func test_api_async_throw_opt() async throws {
        let result = try await subjset.requestWithThrowing(opt: TestInfo.self,
                                                           address: address,
                                                           with: .testMake())
        XCTAssertEqual(info, result)
    }
}
