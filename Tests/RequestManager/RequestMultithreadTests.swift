import Combine
import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestMultithreadTests: XCTestCase {
    private enum Constant {
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
                                  error: RequestError.generic,
                                  delayInSeconds: Constant.stubbedTimeoutInSeconds).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_threads() {
        
    }
}
