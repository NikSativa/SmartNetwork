import Foundation
import SpryKit
import XCTest
@testable import SmartNetwork

final class HTTPStubTest_Tests: XCTestCase {
    private let request: URLRequest = {
        let address: Address = .testMake(scheme: .https,
                                         host: "api.example.com",
                                         path: ["signin", "v1.0"],
                                         queryItems: ["user": "foo"],
                                         shouldAddSlashAfterEndpoint: true)
        let parameter = Parameters.testMake(header: .init(["key": "value"]),
                                            method: .get)
        let repr = try! parameter.urlRequest(for: address)
        return repr.sdk
    }()

    func test_isPath() {
        XCTAssertTrue(HTTPStubCondition.isPath("/signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.isPath("signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.isPath("/signin/v1.0/").test(request))

        XCTAssertFalse(HTTPStubCondition.isPath("signin").test(request))
        XCTAssertFalse(HTTPStubCondition.isPath("signin/").test(request))
        XCTAssertFalse(HTTPStubCondition.isPath("/signin/").test(request))
    }

    func test_pathContains_keepingOrder() {
        XCTAssertTrue(HTTPStubCondition.pathContains("/signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("/signin/v1.0/").test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("signin").test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("signin/").test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("/signin/").test(request))

        XCTAssertFalse(HTTPStubCondition.pathContains("/v1.0/signin/").test(request)) // << -- This is the key difference

        XCTAssertFalse(HTTPStubCondition.pathContains("signin/2.0").test(request))
        XCTAssertFalse(HTTPStubCondition.pathContains("2.0/signin/").test(request))
        XCTAssertFalse(HTTPStubCondition.pathContains("/signin2.0/").test(request))
    }

    func test_pathContains_not_keepingOrder() {
        XCTAssertTrue(HTTPStubCondition.pathContains("/signin/v1.0", keepingOrder: false).test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("signin/v1.0", keepingOrder: false).test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("/signin/v1.0/", keepingOrder: false).test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("signin", keepingOrder: false).test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("signin/", keepingOrder: false).test(request))
        XCTAssertTrue(HTTPStubCondition.pathContains("/signin/", keepingOrder: false).test(request))

        XCTAssertTrue(HTTPStubCondition.pathContains("/v1.0/signin/", keepingOrder: false).test(request)) // << -- This is the key difference

        XCTAssertFalse(HTTPStubCondition.pathContains("signin/2.0", keepingOrder: false).test(request))
        XCTAssertFalse(HTTPStubCondition.pathContains("2.0/signin/", keepingOrder: false).test(request))
        XCTAssertFalse(HTTPStubCondition.pathContains("/signin2.0/", keepingOrder: false).test(request))
        XCTAssertFalse(HTTPStubCondition.pathContains("2.0/signin/", keepingOrder: false).test(request))
        XCTAssertFalse(HTTPStubCondition.pathContains("/signin2.0/", keepingOrder: false).test(request))
    }

    func test_isHost() {
        XCTAssertTrue(HTTPStubCondition.isHost("api.example.com").test(request))
        #if (os(macOS) || os(iOS) || supportsVisionOS) && (arch(x86_64) || arch(arm64))
        XCTAssertThrowsAssertion {
            HTTPStubCondition.isHost("/api.example.com").test(self.request)
        }
        #endif
    }

    func test_isAbsoluteURLString() {
        XCTAssertTrue(HTTPStubCondition.isAbsoluteURLString("https://api.example.com/signin/v1.0/?user=foo").test(request))
        XCTAssertFalse(HTTPStubCondition.isAbsoluteURLString("https://other.example.com/").test(request))
    }

    func test_isMethod() {
        XCTAssertTrue(HTTPStubCondition.isMethod("GET").test(request))
        XCTAssertFalse(HTTPStubCondition.isMethod("POST").test(request))
    }

    func test_isScheme() {
        XCTAssertTrue(HTTPStubCondition.isScheme("https").test(request))
        XCTAssertFalse(HTTPStubCondition.isScheme("http").test(request))
        #if (os(macOS) || os(iOS) || supportsVisionOS) && (arch(x86_64) || arch(arm64))
        XCTAssertThrowsAssertion {
            HTTPStubCondition.isScheme("https://").test(self.request)
        }
        XCTAssertThrowsAssertion {
            HTTPStubCondition.isScheme("https/").test(self.request)
        }
        #endif
    }

    func test_pathStartsWith() {
        XCTAssertTrue(HTTPStubCondition.pathStartsWith("/signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.pathStartsWith("/signin/").test(request))
        XCTAssertTrue(HTTPStubCondition.pathStartsWith("/signin").test(request))

        XCTAssertFalse(HTTPStubCondition.pathStartsWith("/signin/v1.").test(request))
        XCTAssertFalse(HTTPStubCondition.pathStartsWith("/signin/v1").test(request))
        XCTAssertFalse(HTTPStubCondition.pathStartsWith("/signin/v").test(request))
        XCTAssertFalse(HTTPStubCondition.pathStartsWith("/sign").test(request))
    }

    func test_pathEndsWith() {
        XCTAssertTrue(HTTPStubCondition.pathEndsWith("/signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.pathEndsWith("signin/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.pathEndsWith("/v1.0").test(request))
        XCTAssertTrue(HTTPStubCondition.pathEndsWith("v1.0").test(request))

        XCTAssertFalse(HTTPStubCondition.pathEndsWith("ignin/v1.0").test(request))
        XCTAssertFalse(HTTPStubCondition.pathEndsWith("gnin/v1.0").test(request))
        XCTAssertFalse(HTTPStubCondition.pathEndsWith("nin/v1.0").test(request))
        XCTAssertFalse(HTTPStubCondition.pathEndsWith("n/v1.0").test(request))
        XCTAssertFalse(HTTPStubCondition.pathEndsWith("1.0").test(request))
        XCTAssertFalse(HTTPStubCondition.pathEndsWith(".0").test(request))
    }

    func test_pathNSMatches() throws {
        let regexStr = "/(.*)/v1.0"
        XCTAssertTrue(try HTTPStubCondition.pathNSMatches(.init(pattern: regexStr, options: [.caseInsensitive])).test(request))
        XCTAssertFalse(try HTTPStubCondition.pathNSMatches(.init(pattern: regexStr.replacingOccurrences(of: "v1", with: "v2"), options: [.caseInsensitive])).test(request))
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_pathMatches() throws {
        let regexStr = "/(.*)/v1.0"
        XCTAssertTrue(try HTTPStubCondition.pathMatches(.init(regexStr)).test(request))
        XCTAssertFalse(try HTTPStubCondition.pathMatches(.init(regexStr.replacingOccurrences(of: "v1", with: "v2"))).test(request))
    }

    func test_absoluteStringNSMatches() throws {
        let regexStr = "(.*)example.com/(.*)/v1.0/(.*)"
        XCTAssertTrue(try HTTPStubCondition.absoluteStringNSMatches(.init(pattern: regexStr, options: [.caseInsensitive])).test(request))
        XCTAssertFalse(try HTTPStubCondition.absoluteStringNSMatches(.init(pattern: regexStr.replacingOccurrences(of: "v1", with: "v2"), options: [.caseInsensitive])).test(request))
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func test_absoluteStringMatches() throws {
        let regexStr = "(.*)example.com/(.*)/v1.0/(.*)"
        XCTAssertTrue(try HTTPStubCondition.absoluteStringMatches(.init(regexStr)).test(request))
        XCTAssertFalse(try HTTPStubCondition.absoluteStringMatches(.init(regexStr.replacingOccurrences(of: "v1", with: "v2"))).test(request))
    }
}
