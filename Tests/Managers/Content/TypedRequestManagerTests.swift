import Combine
import Foundation
import SmartNetwork
import XCTest

final class TypedRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: Set<AnyCancellable> = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let addressEmpty: Address = .testMake(string: "http://example2.com/signin")
    private let subjset = SmartRequestManager.create().data
    private let info = TestInfo(id: 1)

    override func setUp() {
        super.setUp()

        let response = HTTPStubResponse(statusCode: .accepted, header: [:], body: .encodable(info), error: nil, delayInSeconds: stubbedTimeoutInSeconds)
        HTTPStubServer.shared.add(condition: .isAddress(address), response: response).store(in: &observers)

        _ = HTTPStubServer.shared.add(condition: .isAddress(addressEmpty),
                                      body: .empty,
                                      delayInSeconds: stubbedTimeoutInSeconds).storing(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_api_any() {
        let actual: SendableResult<Data> = .init()
        let exp = expectation(description: #function)
        subjset.request(address: address).complete { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.info())
    }

    func test_api_main() {
        let actual: SendableResult<Data> = .init()
        let exp = expectation(description: #function)
        subjset.request(address: address).complete(in: .absent) { obj in
            actual.value = try? obj.get()
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.info())
    }

    func test_api_main_optional() {
        let actual: SendableResult<Data> = .init()
        let exp = expectation(description: #function)
        SmartRequestManager.create()
            .dataOptional
            .request(address: address).complete(in: .absent) { obj in
                actual.value = try? obj.get()
                exp.fulfill()
            }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.info())
    }

    func test_api_main_optional_empty() {
        let actual: SendableResult<Data> = .init()
        let exp = expectation(description: #function)
        SmartRequestManager.create()
            .dataOptional
            .request(address: addressEmpty).complete(in: .absent) { obj in
                actual.value = try? obj.get()
                exp.fulfill()
            }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(actual.value, nil)
    }

    func test_api_async() async {
        var actual: Data?
        let result = await subjset.request(address: address).async()
        actual = try? result.get()
        XCTAssertEqual(info, actual?.info())
    }

    func test_api_async_throw() async throws {
        let result = try await subjset.request(address: address,
                                               with: .testMake()).asyncWithThrowing()
        XCTAssertEqual(info, result.info())
    }
}
