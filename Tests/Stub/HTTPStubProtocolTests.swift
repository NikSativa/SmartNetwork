import Combine
import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class HTTPStubProtocolTests: XCTestCase {
    private enum Constant {
        static let stubbedTimeoutInSeconds: TimeInterval = 0.2

        static let host = "example1.com"
        static let address: Address = .testMake(string: "http://example1.com/signin")
    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        config.protocolClasses = [HTTPStubProtocol.self]
        let session = URLSession(configuration: config)
        return session
    }()

    private var observers: [AnyCancellable] = []

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_stub_data() async throws {
        HTTPStubServer.shared.add(condition: .isHost(Constant.host),
                                  body: .encodable(TestInfo(id: 1))).store(in: &observers)

        let data = try await session.data(from: Constant.address.url())
        let info = data.0.info()
        XCTAssertEqual(info, .init(id: 1))
        XCTAssertNotNil(data.1)
    }

    func test_stub_error() async throws {
        HTTPStubServer.shared.add(condition: .isHost(Constant.host),
                                  error: RequestError.encoding(.brokenAddress),
                                  delayInSeconds: Constant.stubbedTimeoutInSeconds).store(in: &observers)

        do {
            let _ = try await session.data(from: Constant.address.url())
        } catch {
            let errorDomain = String(reflecting: RequestError.self)
            XCTAssertEqual((error as NSError).domain, errorDomain, error.localizedDescription)
            XCTAssertEqual((error as NSError).code, 2, error.localizedDescription)
        }
    }

    func test_stub_empty() async throws {
        HTTPStubServer.shared.add(condition: .isHost(Constant.host),
                                  body: .empty).store(in: &observers)

        let data = try await session.data(from: Constant.address.url())
        XCTAssertEqual(Data(), data.0)
        XCTAssertNotNil(data.1)
    }

    func test_no_stub() async throws {
        do {
            let _ = try await session.data(from: Constant.address.url())
        } catch {
            XCTAssertEqualAny(error, RequestError.generic, error.localizedDescription)
        }
    }
}
