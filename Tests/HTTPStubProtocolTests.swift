import Combine
import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class HTTPStubProtocolTests: XCTestCase {
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

    func test_stub_urlsession() async throws {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [HTTPStubProtocol.self]
        let session = URLSession(configuration: config)

        let data = try await session.data(from: try Constant.address1.url())
        let info = data.0.info()
        XCTAssertEqual(info, .init(id: 1))
        XCTAssertNotNil(data.1)

        do {
            let _ = try await session.data(from: try Constant.address2.url())
        } catch {
            let errorDomain = String(reflecting: RequestError.self)
            XCTAssertEqual((error as NSError).domain, errorDomain, error.localizedDescription)
        }
    }
}
