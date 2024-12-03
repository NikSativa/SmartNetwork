import Foundation
import SmartNetwork
import SpryKit
import Threading
import XCTest

final class PluginsCurlTests: XCTestCase {
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
    var actual: UnsafeValue<[Plugins.Curl.Component: String?]> = .init(value: [:])
    lazy var subject = Plugins.Curl { [actual] component, _, _, text in
        actual.value[component] = text()
    }

    override func setUp() {
        super.setUp()
        session.stub(.configuration).andReturn(URLSessionConfiguration.default)
    }

    override func tearDown() {
        super.tearDown()
        session.resetCallsAndStubs()
        actual.value = [:]
    }

    func test_empty() throws {
        RequestSettings.curlStartsWithDollar = true

        subject.prepare(parameters, request: requestable, session: session)

        requestable.stub(.sdk).andReturn(request)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        requestable.resetCallsAndStubs()

        XCTAssertEqual(actual.value, [
            .phase: "willSend",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\""
        ], String(describing: actual.value![.curl]))
        actual.value = [:]
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)

        XCTAssertEqual(actual.value, [
            .phase: "didFinish",
            .error: nil,
            .body: "< nil >",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t\"http://www.some.com\""
        ], String(describing: actual.value![.curl]))
    }

    func test_body() throws {
        RequestSettings.curlStartsWithDollar = false

        subject.prepare(parameters, request: requestable, session: session)

        requestable.stub(.sdk).andReturn(request)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        requestable.resetCallsAndStubs()

        XCTAssertEqual(actual.value, [
            .phase: "willSend",
            .curl: "curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\""
        ], String(describing: actual.value![.curl]))
        actual.value = [:]

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)

        XCTAssertEqual(actual.value, [
            .phase: "didFinish",
            .error: nil,
            .body: "{\n  \"id\" : 2\n}",
            .curl: "curl -v \\\n\t-X GET \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\""
        ], String(describing: actual.value![.curl]))
    }

    func test_error() throws {
        RequestSettings.curlStartsWithDollar = true

        subject.prepare(parameters, request: requestable, session: session)

        requestable.stub(.sdk).andReturn(request)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        requestable.resetCallsAndStubs()

        XCTAssertEqual(actual.value, [
            .phase: "willSend",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\""
        ], String(describing: actual.value![.curl]))
        actual.value = [:]

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let data: RequestResult = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)

        XCTAssertEqual(actual.value, [
            .phase: "didFinish",
            .error: "generic",
            .body: "{\n  \"id\" : 2\n}",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some2=value2\""
        ], String(describing: actual.value![.curl]))
    }
}
