import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class UserInfoTests: XCTestCase {
    func test_init() {
        var subject: UserInfo = .init()

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

    func test_description() {
        var subject: UserInfo = .init()
        XCTAssertEqual(subject.description, "{}")
        XCTAssertEqual(subject.debugDescription, "{}")

        subject.smartRequestAddress = "address"
        var expected =
            """
            {
              "SmartNetwork.SmartTask.Request.Address.Key" : "address"
            }
            """
        XCTAssertEqual(subject.description, expected)
        XCTAssertEqual(subject.debugDescription, expected)

        subject = [
            "int": 1,
            "str": "text",
            "obj": TestInfo(id: 1)
        ]
        expected =
            """
            {
              "int" : "1",
              "obj" : "{\\n  \\"id\\" : 1\\n}",
              "str" : "text"
            }
            """
        XCTAssertEqual(subject.description, expected)
        XCTAssertEqual(subject.debugDescription, expected)

        subject = [:]
        subject.smartRequestAddress = Address.testMake()
        expected =
            """
            {
              "SmartNetwork.SmartTask.Request.Address.Key" : "https://www.apple.com"
            }
            """
        XCTAssertEqual(subject.description, expected)
        XCTAssertEqual(subject.debugDescription, expected)
    }

    func test_multiThreadSafety() {
        let subject: UserInfo = .init()

        var exps: [XCTestExpectation] = []
        for i in 0..<10000 {
            let exp = expectation(description: "\(i)")
            exps.append(exp)
            DispatchQueue.global().async { [subject] in
                let new = Int.random(in: 0..<1000)
                subject["b"] = new // async write
                XCTAssertTrue(subject["b"] != Optional<Int>.none) // async read
                exp.fulfill()
            }
        }
        wait(for: exps, timeout: 1.0)

        XCTAssertTrue(subject["b"] != Optional<Int>.none)
    }
}
