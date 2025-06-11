#if swift(>=6.0) && canImport(SwiftSyntax600)
import Foundation
import SpryKit
import Threading
import XCTest
@testable import SmartNetwork

final class PluginsCurlTests: XCTestCase {
    let url = URL.spry.testMake("https://www.some.com?some=value")
    let headerFields: [String: String] = ["some": "value"]
    lazy var body: Body = .encode(TestInfo(id: 2))

    let userInfo: UserInfo = .testMake()
    let parameters: Parameters = .testMake()
    let session: FakeSmartURLSession = .init()
    lazy var requestable: FakeURLRequestRepresentation = .init()
    var actual: UnsafeValue<Plugins.Log.DataCollection> = .init(value: .init())
    lazy var subject = Plugins.Log { [actual] data in
        actual.value = data
    }

    override func setUp() {
        super.setUp()
        let request: URLRequest = {
            var request = URLRequest(url: url)
            for field in headerFields {
                request.addValue(field.value, forHTTPHeaderField: field.key)
            }
            request.httpBody = try? body.encode().httpBody
            return request
        }()

        session.stub(.configuration).andReturn(URLSessionConfiguration.default)
        requestable.stub(.sdk_get).andReturn(request)
        requestable.stub(.allHTTPHeaderFields_get).andReturn([:])
        requestable.stub(.url_get).andReturn(URL.spry.testMake())
    }

    override func tearDown() {
        super.tearDown()
        SmartNetworkSettings.curlPrettyPrinted = false
        SmartNetworkSettings.curlStartsWithDollar = false
        session.resetCallsAndStubs()
        requestable.resetCallsAndStubs()
        actual.value = .init()
    }

    func test_empty() async throws {
        SmartNetworkSettings.curlStartsWithDollar = true
        SmartNetworkSettings.curlPrettyPrinted = true

        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "willSend",
            .url: "http://www.some.com",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \'some: value\' \\\n\t-d \'{\n  \"id\" : 2\n}\' \\\n\t\'https://www.some.com?some=value\'"
        ])
        actual.value = .init()
        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: .testMake())

        let data: SmartResponse = .testMake(url: .spry.testMake(), statusCode: 222)
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, .spry.testMake())
        XCTAssertNil(data.urlError)
        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "didFinish",
            .url: "http://www.some.com",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t'http://www.some.com'"
        ])

        subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }

    func test_body() async throws {
        SmartNetworkSettings.curlStartsWithDollar = false
        SmartNetworkSettings.curlPrettyPrinted = false

        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertEqual(actual.value.toTestable(), [
            .url: "http://www.some.com",
            .phase: "willSend",
            .curl: "curl -v \\\n\t-X GET \\\n\t-H 'some: value' \\\n\t-d '{\"id\":2}' \\\n\t'https://www.some.com?some=value'"
        ])
        actual.value = .init()

        subject.didReceive(parameters: parameters, userInfo: userInfo, request: requestable, data: .testMake())

        let data: SmartResponse = .testMake(url: url, statusCode: 222, body: .encode(TestInfo(id: 2)))
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)
        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "didFinish",
            .url: "https://www.some.com?some=value",
            .body: "{\n  \"id\" : 2\n}",
            .curl: "curl -v \\\n\t-X GET \\\n\t-d '{\"id\":2}' \\\n\t'https://www.some.com?some=value'"
        ])

        subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
    }

    func test_error() async throws {
        SmartNetworkSettings.curlStartsWithDollar = true

        await subject.prepare(parameters: parameters, userInfo: userInfo, request: requestable, session: session)
        subject.willSend(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "willSend",
            .url: "http://www.some.com",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H \'some: value\' \\\n\t-d \'{\"id\":2}\' \\\n\t\'https://www.some.com?some=value\'"
        ])
        actual.value = .init()

        let url = URL.spry.testMake("https://www.some.com?some2=value2")
        let data: SmartResponse = .testMake(url: url, statusCode: 222, headerFields: ["some": "value"], body: .encode(TestInfo(id: 2)), error: RequestError.generic)
        try subject.verify(parameters: parameters, userInfo: userInfo, data: data)
        subject.didFinish(parameters: parameters, userInfo: userInfo, data: data)

        XCTAssertEqual(data.url, url)
        XCTAssertNil(data.urlError)
        XCTAssertEqual(actual.value.toTestable(), [
            .phase: "didFinish",
            .curl: "$ curl -v \\\n\t-X GET \\\n\t-H 'some: value' \\\n\t-d '{\"id\":2}' \\\n\t'https://www.some.com?some2=value2'",
            .error: "generic",
            .requestError: "generic",
            .body: "{\n  \"id\" : 2\n}",
            .url: "https://www.some.com?some2=value2"
        ])

        subject.wasCancelled(parameters: parameters, userInfo: userInfo, request: requestable, session: session)

        XCTAssertHaveReceived(requestable, .sdk_get, countSpecifier: .atLeast(1))
        XCTAssertHaveReceived(requestable, .allHTTPHeaderFields_get, countSpecifier: .atLeast(1))
        XCTAssertHaveNotReceived(requestable, .url_set)
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
#endif
