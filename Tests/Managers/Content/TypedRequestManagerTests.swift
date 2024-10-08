import Combine
import Foundation
import SmartNetwork
import XCTest

final class TypedRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: [AnyCancellable] = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let subjset = RequestManager.create().data
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
        let actual: SendableResult<Data> = .init()
        let exp = expectation(description: #function)
        subjset.request(address: address) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.info())
    }

    func test_api_main() {
        let actual: SendableResult<Data> = .init()
        let exp = expectation(description: #function)
        subjset.request(address: address,
                        with: .testMake(),
                        inQueue: .absent) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.info())
    }

    func test_api_async() async {
        var actual: Data?
        let result = await subjset.request(address: address,
                                           with: .testMake())
        actual = try? result.get()
        XCTAssertEqual(info, actual?.info())
    }

    func test_api_async_throw() async throws {
        let result = try await subjset.requestWithThrowing(address: address,
                                                           with: .testMake())
        XCTAssertEqual(info, result.info())
    }
}
