import Combine
import Foundation
import SmartNetwork
import XCTest

final class PureRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: [AnyCancellable] = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let subject = SmartRequestManager.create()
    private let info = TestInfo(id: 1)

    override func setUp() {
        super.setUp()

        let response = HTTPStubResponse(statusCode: .accepted, header: HeaderFields(), body: .encodable(info), error: nil, delayInSeconds: stubbedTimeoutInSeconds)
        HTTPStubServer.shared.add(condition: .isAddress(address), response: response).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_api_any() {
        let actual: UnsafeValue<SmartResponse> = .init()
        let exp = expectation(description: #function)
        subject.request(address: address)
            .complete { obj in
                actual.value = obj
                exp.fulfill()
            }
            .deferredStart()
            .store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.body?.info())
    }

    func test_api_main() {
        let actual: UnsafeValue<SmartResponse> = .init()
        let exp = expectation(description: #function)
        subject.request(address: address,
                        parameters: .testMake(),
                        userInfo: .testMake(),
                        completionQueue: .absent) { obj in
            actual.value = obj
            exp.fulfill()
        }
        .deferredStart()
        .store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual.value?.body?.info())
    }

    func test_api_async() async {
        let result = await subject.request(address: address, parameters: .testMake())
        XCTAssertEqual(info, result.body?.info())
    }
}
