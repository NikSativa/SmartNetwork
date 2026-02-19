import Foundation
import XCTest
@testable import SmartNetwork

final class ParametersTests: XCTestCase {
    func test_plus_headers_preserves_shouldIgnoreStopTheLine() {
        let base = Parameters(shouldIgnoreStopTheLine: true)
        let result = base + HeaderFields(["x-test": "1"])
        XCTAssertTrue(result.shouldIgnoreStopTheLine)
    }

    func test_plus_plugins_preserves_shouldIgnoreStopTheLine() {
        let plugin = Plugins.JSONHeaders()
        let base = Parameters(shouldIgnoreStopTheLine: true)
        let result = base + [plugin]
        XCTAssertTrue(result.shouldIgnoreStopTheLine)
    }

    func test_url_request_for_url_matches_smart_url_overload() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/path"))
        let parameters = Parameters(header: ["X-Test": "1"],
                                    method: .post,
                                    body: .data(Data([0x01, 0x02])),
                                    requestPolicy: .reloadIgnoringLocalCacheData,
                                    timeoutInterval: 7)

        let requestFromSmartURL = try parameters.urlRequest(for: .url(url))
        let requestFromURL = try parameters.urlRequest(for: url)

        XCTAssertEqual(requestFromSmartURL.sdk.url, requestFromURL.sdk.url)
        XCTAssertEqual(requestFromSmartURL.sdk.httpMethod, requestFromURL.sdk.httpMethod)
        XCTAssertEqual(requestFromSmartURL.sdk.httpBody, requestFromURL.sdk.httpBody)
        XCTAssertEqual(requestFromSmartURL.sdk.timeoutInterval, requestFromURL.sdk.timeoutInterval)
        XCTAssertEqual(requestFromSmartURL.sdk.cachePolicy, requestFromURL.sdk.cachePolicy)
        XCTAssertEqual(requestFromSmartURL.sdk.value(forHTTPHeaderField: "X-Test"),
                       requestFromURL.sdk.value(forHTTPHeaderField: "X-Test"))
    }
}
