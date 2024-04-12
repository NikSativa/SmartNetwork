import Combine
import Foundation
import SmartNetwork
import XCTest

final class PureRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: [AnyCancellable] = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let subjset = RequestManager.create().pure
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
        var actual: RequestResult?
        let exp = expectation(description: #function)
        subjset.request(address: address) { obj in
            actual = obj
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual?.body?.info())
    }

    func test_api_main() {
        var actual: RequestResult?
        let exp = expectation(description: #function)
        subjset.request(address: address,
                        with: .testMake(),
                        inQueue: .absent) { obj in
            actual = obj
            exp.fulfill()
        }.deferredStart().store(in: &observers)
        wait(for: [exp], timeout: timeoutInSeconds)
        XCTAssertEqual(info, actual?.body?.info())
    }

    func test_api_async() async {
        let result = await subjset.request(address: address,
                                           with: .testMake())
        XCTAssertEqual(info, result.body?.info())
    }
}
