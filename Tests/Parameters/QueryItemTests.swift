import Foundation
import XCTest

@testable import SmartNetwork

final class QueryItemTests: XCTestCase {
    func test_description() {
        XCTAssertEqual(QueryItem(key: "key", value: nil).description, "key")
        XCTAssertEqual(QueryItem(key: "key", value: nil).debugDescription, "key")
        XCTAssertEqual(QueryItem(key: "key", value: "value").description, "key: value")
        XCTAssertEqual(QueryItem(key: "key", value: "value").debugDescription, "key: value")
    }
}
