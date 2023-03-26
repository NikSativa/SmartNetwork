import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class HTTPMethodTests: XCTestCase {
    func test_string() {
        let methods: [HTTPMethod] = [
            .get,
            .head,
            .post,
            .put,
            .delete,
            .connect,
            .options,
            .trace,
            .patch
        ]

        for method in methods {
            let expected = String(reflecting: method).components(separatedBy: ".").last
            XCTAssertEqual(method.toString(), expected?.uppercased())
        }

        XCTAssertEqual(HTTPMethod.other("other").toString(), "other")
    }
}
