import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class PluginsCurlOSTests: XCTestCase {
    let url = URL.spry.testMake("https://www.some.com?some=value")
    let headerFields: [String: String] = ["some": "value"]
    lazy var body: Body = .encode(TestInfo(id: 2))

    lazy var request: URLRequest = {
        var request = URLRequest(url: url)
        for field in headerFields {
            request.addValue(field.value, forHTTPHeaderField: field.key)
        }
        request.httpBody = body.data
        return request
    }()

    let parameters: Parameters = .testMake()
    let session: FakeSmartURLSession = .init()
    lazy var requestable: FakeURLRequestRepresentation = .init()

    override func setUp() {
        super.setUp()
        session.stub(.configuration).andReturn(URLSessionConfiguration.default)

        requestable.stub(.sdk).andReturn(request)
        requestable.stub(.allHTTPHeaderFields).andReturn([:])
        requestable.stub(.url).andReturn(URL.spry.testMake())
    }

    override func tearDown() {
        super.tearDown()
        session.resetCallsAndStubs()
        requestable.resetCallsAndStubs()
    }

    func test_empty() throws {
        let subject = Plugins.LogOS(shouldPrintBody: true)
        subject.prepare(parameters, request: requestable, session: session)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)

        subject.wasCancelled(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url)
    }

    func test_body() throws {
        let subject = Plugins.LogOS(shouldPrintBody: false)
        subject.prepare(parameters, request: requestable, session: session)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)

        subject.wasCancelled(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url)
    }

    func test_error() throws {
        let subject = Plugins.LogOS(shouldPrintBody: true)
        subject.prepare(parameters, request: requestable, session: session)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let data: RequestResult = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)

        subject.wasCancelled(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url)
    }
}
