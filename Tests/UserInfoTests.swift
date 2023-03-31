import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class UserInfoTests: XCTestCase {
    func test_init() {
        var subject: UserInfo

        subject = .init()
        XCTAssert(subject.isEmpty)
        XCTAssertEqual(subject.values.count, 0)

        subject = [:]
        XCTAssert(subject.isEmpty)
        XCTAssertEqual(subject.values.count, 0)

        subject = [
            "int": 1,
            "str": "text",
            "obj": TestInfo(id: 1)
        ]
        XCTAssert(!subject.isEmpty)
        XCTAssertEqual(subject.values.count, 3)

        subject["obj"] = TestInfo(id: 2)
        XCTAssert(!subject.isEmpty)
        XCTAssertEqual(subject.values.count, 3)

        XCTAssertEqual(subject["int"], 1)
        XCTAssertNotNil(subject.value(of: Any.self, for: "int"))
        XCTAssertEqual(subject.value(of: Any.self, for: "int") as? Int, 1)
        XCTAssertNil(subject.value(of: String.self, for: "int"))
        XCTAssertNil(subject.value(of: TestInfo.self, for: "int"))

        XCTAssertEqual(subject["str"], "text")
        XCTAssertNotNil(subject.value(of: Any.self, for: "str"))
        XCTAssertEqual(subject.value(of: Any.self, for: "str") as? String, "text")
        XCTAssertNil(subject.value(of: Int.self, for: "str"))
        XCTAssertNil(subject.value(of: TestInfo.self, for: "str"))

        XCTAssertEqual(subject["obj"], TestInfo(id: 2))
        XCTAssertNotNil(subject.value(of: Any.self, for: "obj"))
        XCTAssertEqual(subject.value(of: Any.self, for: "obj") as? TestInfo, TestInfo(id: 2))
        XCTAssertNil(subject.value(of: Int.self, for: "obj"))
        XCTAssertNil(subject.value(of: String.self, for: "obj"))
    }
}
