#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class PluginsCurlOSTests: XCTestCase {
    let url = URL.spry.testMake("https://www.some.com?some=value")
    let headerFields: [String: String] = ["some": "value"]
    lazy var body: HTTPBody = .encode(TestInfo(id: 2))

    let userInfo: UserInfo = .testMake()
    let parameters: Parameters = .testMake()
    let session: FakeSmartURLSession = .init()
    lazy var requestable: FakeURLRequestRepresentation = .init()

    override func setUp() {
        super.setUp()
        session.stub(.configuration).andReturn(URLSessionConfiguration.default)

        let request: URLRequest = {
            var request = URLRequest(url: url)
            for field in headerFields {
                request.addValue(field.value, forHTTPHeaderField: field.key)
            }
            try? body.encode().fill(&request)
            return request
        }()

        requestable.stub(.sdk_get).andReturn(request)
        requestable.stub(.allHTTPHeaderFields_get).andReturn([:])
        requestable.stub(.url_get).andReturn(URL.spry.testMake())
    }

    override func tearDown() {
        super.tearDown()
        session.resetCallsAndStubs()
        requestable.resetCallsAndStubs()
    }

    func test_empty() async throws {
        let subject = Plugins.LogOS(shouldPrintBody: true)
        try await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, response: .testMake())

        let response: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        try await subject.verify(parameters: parameters, userInfo: userInfo, response: response)
        await subject.didFinish(parameters: parameters, userInfo: userInfo, response: response)

        XCTAssertEqual(response.url, .spry.testMake())
        XCTAssertNil(response.urlError)

        await subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }

    func test_body() async throws {
        let subject = Plugins.LogOS(shouldPrintBody: false)
        try await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, response: .testMake())

        let response: SmartResponse = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try await subject.verify(parameters: parameters, userInfo: userInfo, response: response)
        await subject.didFinish(parameters: parameters, userInfo: userInfo, response: response)

        XCTAssertEqual(response.url, url)
        XCTAssertNil(response.urlError)

        await subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }

    func test_error() async throws {
        let subject = Plugins.LogOS(shouldPrintBody: true)
        try await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        await subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, response: .testMake())

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let response: SmartResponse = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try await subject.verify(parameters: parameters, userInfo: userInfo, response: response)
        await subject.didFinish(parameters: parameters, userInfo: userInfo, response: response)

        XCTAssertEqual(response.url, url)
        XCTAssertNil(response.urlError)

        await subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }
}
#endif
