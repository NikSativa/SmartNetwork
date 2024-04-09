import Foundation
import XCTest

@testable import SmartNetwork
@testable import SmartNetworkTestHelpers

final class QueryItemsTests: XCTestCase {
    func test_item() {
        var subject: QueryItems = []
        XCTAssertTrue(subject.isEmpty)

        subject.append(key: "item", value: nil)
        subject.append(key: "item", value: "1")
        subject.append(key: "item2", value: "value2")
        subject.append(key: "item", value: "2")
        XCTAssertEqual(subject, [
            .testMake(key: "item", value: nil),
            .testMake(key: "item", value: "1"),
            .testMake(key: "item2", value: "value2"),
            .testMake(key: "item", value: "2")
        ])

        subject.set(key: "item", value: "value")
        XCTAssertEqual(subject, [
            .testMake(key: "item2", value: "value2"),
            .testMake(key: "item", value: "value")
        ])

        XCTAssertEqual(QueryItem(key: "key", value: nil).description, "key")
        XCTAssertEqual(QueryItem(key: "key", value: nil).debugDescription, "key")
        XCTAssertEqual(QueryItem(key: "key", value: "value").description, "key: value")
        XCTAssertEqual(QueryItem(key: "key", value: "value").debugDescription, "key: value")
    }
}
