import Foundation
import SmartNetwork
import XCTest

final class DecodableKeyPathTests: XCTestCase {
    func test_init_string() {
        var subject: DecodableKeyPath<String> = "/p1/"
        XCTAssertEqual(subject.path, ["p1"])

        subject = "p1"
        XCTAssertEqual(subject.path, ["p1"])

        subject = "/p1/p2/"
        XCTAssertEqual(subject.path, ["p1", "p2"])

        subject = "p1/p2"
        XCTAssertEqual(subject.path, ["p1", "p2"])

        subject = "p1\\p2"
        XCTAssertEqual(subject.path, ["p1\\p2"])

        subject = "p1p2"
        XCTAssertEqual(subject.path, ["p1p2"])
    }

    func test_init_array() {
        var subject: DecodableKeyPath<String> = ["p1"]
        XCTAssertEqual(subject.path, ["p1"])

        subject = ["/p1/"]
        XCTAssertEqual(subject.path, ["/p1/"])

        subject = ["/p1/p2/"]
        XCTAssertEqual(subject.path, ["/p1/p2/"])

        subject = ["p1", "p2"]
        XCTAssertEqual(subject.path, ["p1", "p2"])

        subject = ["p1p2"]
        XCTAssertEqual(subject.path, ["p1p2"])
    }
}
