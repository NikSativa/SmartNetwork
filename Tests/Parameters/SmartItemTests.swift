import Foundation
import SmartNetwork
import XCTest

final class QueryItemTests: XCTestCase {
    func test_description() {
        XCTAssertEqual(SmartItem<String?>(key: "key", value: nil).description, "key: nil")
        XCTAssertEqual(SmartItem<String?>(key: "key", value: nil).debugDescription, "key: nil")
        XCTAssertEqual(SmartItem<String?>(key: "key", value: "value").description, "key: value")
        XCTAssertEqual(SmartItem<String?>(key: "key", value: "value").debugDescription, "key: value")
    }
}
