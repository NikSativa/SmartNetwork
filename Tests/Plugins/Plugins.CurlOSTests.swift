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
        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: .testMake())

        let data: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)

        subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }

    func test_body() async throws {
        let subject = Plugins.LogOS(shouldPrintBody: false)
        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: .testMake())

        let data: SmartResponse = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)

        subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }

    func test_error() async throws {
        let subject = Plugins.LogOS(shouldPrintBody: true)
        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: .testMake())

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let data: SmartResponse = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)

        subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }
}
#endif
