import Combine
import Foundation
import SmartNetwork
import Threading
import XCTest

final class DecodableRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: [AnyCancellable] = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let subject = SmartRequestManager.create().decodable
    private let info = TestInfo(id: 1)

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isAddress(address),
                                  header: ["": ""],
                                  body: .encode(info),
                                  delayInSeconds: stubbedTimeoutInSeconds)
            .store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_api_any() {
        let actual: SendableResult<TestInfo> = .init()
        let exp = expectation(description: #function)
        subject.request(TestInfo.self, address: address) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart(in: Queue.main).store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)
    }

    func test_api_main() {
        let actual: SendableResult<TestInfo> = .init()
        let exp = expectation(description: #function)
        subject.request(TestInfo.self,
                        address: address,
                        parameters: .testMake(),
                        completionQueue: .absent) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)
    }

    func test_api_main_opt() {
        let actual: SendableResult<TestInfo> = .init()
        let exp = expectation(description: #function)
        subject.requestOptional(TestInfo.self,
                                address: address,
                                parameters: .testMake(),
                                completionQueue: .absent) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)
    }

    func test_api_async() async {
        var actual: TestInfo?
        let result = await subject.request(TestInfo.self,
                                           address: address,
                                           parameters: .testMake())
        actual = try? result.get()
        XCTAssertEqual(info, actual)
    }

    func test_api_async_opt() async {
        var actual: TestInfo?
        let result = await subject.requestOptional(TestInfo.self,
                                                   address: address,
                                                   parameters: .testMake())
        actual = try? result.get()
        XCTAssertEqual(info, actual)
    }

    func test_api_async_throw() async throws {
        let result = try await subject.requestWithThrowing(TestInfo.self,
                                                           address: address,
                                                           parameters: .testMake())
        XCTAssertEqual(info, result)
    }

    func test_api_async_throw_opt() async throws {
        let result = try await subject.requestOptionalWithThrowing(TestInfo.self,
                                                                   address: address,
                                                                   parameters: .testMake())
        XCTAssertEqual(info, result)
    }
}
