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
    lazy var requestable: FakeURLRequestRepresentation = .init()

    func test_empty() throws {
        let subject = Plugins.CurlOS(shouldPrintBody: true)
        subject.prepare(parameters, request: requestable)

        requestable.stub(.sdk).andReturn(request)
        subject.willSend(parameters, request: requestable, userInfo: .testMake())
        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        requestable.resetCallsAndStubs()

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)
    }

    func test_body() throws {
        let subject = Plugins.CurlOS(shouldPrintBody: false)
        subject.prepare(parameters, request: requestable)

        requestable.stub(.sdk).andReturn(request)
        subject.willSend(parameters, request: requestable, userInfo: .testMake())
        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        requestable.resetCallsAndStubs()

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)
    }

    func test_error() throws {
        let subject = Plugins.CurlOS(shouldPrintBody: true)
        subject.prepare(parameters, request: requestable)

        requestable.stub(.sdk).andReturn(request)
        subject.willSend(parameters, request: requestable, userInfo: .testMake())
        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        requestable.resetCallsAndStubs()

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let data: RequestResult = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)
    }
}
