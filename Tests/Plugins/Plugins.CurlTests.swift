import Foundation
import SpryKit
import Threading
import XCTest

@testable import SmartNetwork

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
    var actual: UnsafeValue<Plugins.Log.DataCollection> = .init(value: .init())
    lazy var subject = Plugins.Log { [actual] data in
        actual.value = data
    }

    override func setUp() {
        super.setUp()
        session.stub(.configuration).andReturn(URLSessionConfiguration.default)
        requestable.stub(.sdk).andReturn(request)
        requestable.stub(.allHTTPHeaderFields).andReturn([:])
        requestable.stub(.url).andReturn(URL.spry.testMake())
    }

    override func tearDown() {
        super.tearDown()
        RequestSettings.curlPrettyPrinted = false
        RequestSettings.curlStartsWithDollar = false
        session.resetCallsAndStubs()
        requestable.resetCallsAndStubs()
        actual.value = .init()
    }

    func test_empty() throws {
        RequestSettings.curlStartsWithDollar = true
        RequestSettings.curlPrettyPrinted = true

        subject.prepare(parameters, request: requestable, session: session)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)
        XCTAssertEqual(actual.value.toTestable(), [
            .url: "http://www.some.com",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\" | json_pp",
            .phase: "willSend"
        ])
        actual.value = .init()
        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)

        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "didFinish",
            .url: "http://www.some.com",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t\"http://www.some.com\" | json_pp"
        ])

        subject.wasCancelled(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url)
    }

    func test_body() throws {
        RequestSettings.curlStartsWithDollar = false
        RequestSettings.curlPrettyPrinted = false

        subject.prepare(parameters, request: requestable, session: session)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertEqual(actual.value.toTestable(), [
            .url: "http://www.some.com",
            .curl: "curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\"",
            .phase: "willSend"
        ])
        actual.value = .init()

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let data: RequestResult = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)
        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "didFinish",
            .url: "https://www.some.com?some=value",
            .body: "{\n  \"id\" : 2\n}",
            .curl: "curl -v \\\n\t-X GET \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\""
        ])

        subject.wasCancelled(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url)
    }

    func test_error() throws {
        RequestSettings.curlStartsWithDollar = true

        subject.prepare(parameters, request: requestable, session: session)
        subject.willSend(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "willSend",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some=value\"",
            .url: "http://www.some.com"
        ])
        actual.value = .init()

        subject.didReceive(parameters, request: requestable, data: .testMake(), userInfo: .testMake())

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let data: RequestResult = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try subject.verify(data: data, userInfo: .testMake())
        subject.didFinish(withData: data, userInfo: .testMake())

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)
        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "didFinish",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \"some: value\" \\\n\t-d \"{\\\"id\\\":2}\" \\\n\t\"https://www.some.com?some2=value2\"",
            .error: "generic",
            .requestError: "generic",
            .body: "{\n  \"id\" : 2\n}",
            .url: "https://www.some.com?some2=value2"
        ])

        subject.wasCancelled(parameters, request: requestable, userInfo: .testMake(), session: session)

        XCTAssertHaveReceived(requestable, .sdk, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url)
    }
}

extension Plugins.Log.DataCollection {
    func toTestable() -> [Plugins.Log.Component: String] {
        return data.compactMapValues { value in
            let value = value()
            if let value = value as? String {
                return value
            } else if let value = rawable(value) {
                return value
            } else if let value = value as? RequestError {
                return value.subname
            } else {
                return nil
            }
        }
    }
}
