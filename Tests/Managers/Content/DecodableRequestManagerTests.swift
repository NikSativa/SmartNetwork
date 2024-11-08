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
        let actual: UnsafeValue<TestInfo> = .init()
        let exp = expectation(description: #function)
        subject.request(TestInfo.self, address: address) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart(in: Queue.main).store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value)

//        let result = run_test(TestInfo.self) { subject, completion in
//            return subject.request(TestInfo.self, address: address, completionQueue: .absent, completion: completion)
//        }
//        XCTAssertTrue(result.info() == info)
    }

    private func run_test<T>(_: T.Type, _ subject: (DecodableRequestManager, (Result<T, Error>) -> Void) -> SmartTasking) -> Result<T, Error>? {
        let actual: UnsafeResult<T> = .init()
        let exp = expectation(description: #function)
        let manager = SmartRequestManager.create().decodable

        subject(manager) { obj in
            actual.value = obj
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: [exp], timeout: timeoutInSeconds)
        return actual.value
    }

    func test_api_main() {
        let actual: UnsafeValue<TestInfo> = .init()
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
        let actual: UnsafeValue<TestInfo> = .init()
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
