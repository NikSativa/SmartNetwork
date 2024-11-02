import Foundation
import XCTest

@testable import SmartNetwork

final class HTTPStubBodyTests: XCTestCase {
    func test_empty() {
        XCTAssertNil(HTTPStubBody.empty.data)
    }

    func test_file() {
        let body: HTTPStubBody = .file(name: "HTTPStubBody.json", bundle: .module)
        XCTAssertNotNil(body.data)
        XCTAssertEqual(body.data?.info(), .init(id: 1))

        XCTAssertNil(HTTPStubBody.file(name: "absent.json", bundle: .module).data)
    }

    func test_filePath() {
        let body: HTTPStubBody = .filePath(path: Bundle.module.path(forResource: "HTTPStubBody", ofType: "json") ?? "")

        HTTPStubBody.iOSVerificationEnabled = false
        XCTAssertNotNil(body.data)
        XCTAssertEqual(body.data?.info(), .init(id: 1))

        HTTPStubBody.iOSVerificationEnabled = true
        XCTAssertNotNil(body.data)
        XCTAssertEqual(body.data?.info(), .init(id: 1))
    }

    func test_data() {
        let data = "Data".data(using: .utf8).unsafelyUnwrapped
        XCTAssertEqual(HTTPStubBody.data(data).data, data)
    }

    func test_encodable() {
        let info = TestInfo(id: 1)
        let body: HTTPStubBody = .encode(info)
        XCTAssertNotNil(body.data)
        XCTAssertEqual(body.data?.info(), info)
    }

    func test_encodableWithEncoder() {
        let info = TestInfo(id: 1)
        let body: HTTPStubBody = .encode(info, with: .init())
        XCTAssertNotNil(body.data)
        XCTAssertEqual(body.data?.info(), info)
    }
}
