import Combine
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class HTTPStubProtocolTests: XCTestCase {
    private enum Constant {
        static let stubbedTimeoutInSeconds: TimeInterval = 0.2

        static let host = "example1_lkjghasdkjlahgsdfkasjhdgf_akshdkajhsda_aksdkajshdkajshd.com"
        static let url: SmartURL = .testMake(string: "http://\(host)/signin")
    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        config.protocolClasses = [HTTPStubProtocol.self]
        let session = URLSession(configuration: config)
        return session
    }()

    private var request: URLRequest {
        get throws {
            var request = try URLRequest(url: Constant.url.url())
            request.timeoutInterval = 3
            return request
        }
    }

    private var observers: [AnyCancellable] = []

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_stub_data() async throws {
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.host),
                 body: .encode(TestInfo(id: 1)))
            .store(in: &observers)

        let result = try await session.data(for: request)
        let info = result.0.info()
        XCTAssertEqual(info, .init(id: 1))
        XCTAssertNotNil(result.1)
    }

    func test_stub_error() async {
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.host),
                 error: RequestError.encoding(.brokenAddress),
                 delayInSeconds: Constant.stubbedTimeoutInSeconds)
            .store(in: &observers)

        do {
            _ = try await session.data(for: request)
            XCTFail("Should throw an error")
        } catch {
            #if os(watchOS)
            XCTAssertEqual((error as NSError).domain, NSURLErrorDomain, (error as NSError).domain)
            XCTAssertEqual((error as NSError).code, -1003, error.localizedDescription)
            #else
            let errorDomain = String(reflecting: RequestError.self)
            XCTAssertEqual((error as NSError).domain, errorDomain, (error as NSError).domain)
            XCTAssertEqual((error as NSError).code, 2, error.localizedDescription)
            #endif
        }
    }

    func test_stub_empty() async throws {
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.host),
                 body: .empty)
            .store(in: &observers)

        let result = try await session.data(for: request)
        XCTAssertEqual(Data(), result.0)
        XCTAssertNotNil(result.1)
    }

    func test_no_stub() async {
        do {
            _ = try await session.data(for: request)
            XCTFail("Should throw an error")
        } catch {
            XCTAssertEqual((error as NSError).domain, "NSURLErrorDomain", error.localizedDescription)
//            XCTAssertEqual((error as NSError).code, -1003, error.localizedDescription) or -1001, -1002
        }
    }

    func test_cancelled_request_does_not_deliver_stubbed_body() throws {
        HTTPStubServer.shared
            .add(condition: .isHost(Constant.host),
                 body: .encode(TestInfo(id: 1)),
                 delayInSeconds: Constant.stubbedTimeoutInSeconds)
            .store(in: &observers)

        let completion = expectation(description: "completion")
        let hasData: UnsafeValue<Bool> = .init(value: false)
        let resultError: UnsafeValue<Error?> = .init()

        let task = try session.dataTask(with: request) { data, _, error in
            hasData.value = data != nil
            resultError.value = error
            completion.fulfill()
        }

        task.resume()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
            task.cancel()
        }

        wait(for: [completion], timeout: 2)
        XCTAssertFalse(hasData.value)
        XCTAssertEqual((resultError.value as? URLError)?.code, .cancelled)
    }
}
