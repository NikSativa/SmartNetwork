import XCTest
@testable import SmartNetwork

final class CURLConvertibleTests: XCTestCase {
    struct DummyConvertible: CURLConvertible {}

    override func setUp() {
        super.setUp()
        SmartNetworkSettings.curlAddJSON_PP = false
    }

    func testBasicGetRequest() {
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpMethod = "GET"

        let curl = DummyConvertible().cURLDescription(with: session, request: request, prettyPrinted: false)

        XCTAssertTrue(curl.contains("curl -v"))
        XCTAssertTrue(curl.contains("-X GET"))
        XCTAssertTrue(curl.contains("'https://example.com'"))
    }

    func testRequestWithHeaders() {
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let curl = DummyConvertible().cURLDescription(with: session, request: request, prettyPrinted: false)

        XCTAssertTrue(curl.contains("-H 'Content-Type: application/json'"))
    }

    func testPostRequestWithBody() {
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: URL(string: "https://example.com/api")!)
        request.httpMethod = "POST"
        request.httpBody = "{\"key\":\"value\"}".data(using: .utf8)

        let curl = DummyConvertible().cURLDescription(with: session, request: request, prettyPrinted: false)

        XCTAssertTrue(curl.contains("-X POST"))
        XCTAssertTrue(curl.contains("-d '{\"key\":\"value\"}'"))
    }

    func testPrettyPrintedJSON() {
        SmartNetworkSettings.curlAddJSON_PP = true
        let session = URLSession(configuration: .ephemeral)
        var request = URLRequest(url: URL(string: "https://example.com")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["foo": "bar"], options: [])

        let curl = DummyConvertible().cURLDescription(with: session, request: request, prettyPrinted: true)

        XCTAssertTrue(curl.contains(" | json_pp"))
        XCTAssertTrue(curl.contains("-d '{"))
    }
}
