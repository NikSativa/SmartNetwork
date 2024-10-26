import Foundation
import SmartNetwork
import XCTest

final class DecodeByKeyPathTests: XCTestCase {
    private struct Person: Decodable, Equatable {
        let name: String
    }

    func test_decoding_key() {
        run_test(json: "", keyPath: "person", expected: nil)
        run_test(json: "{}", keyPath: "person", expected: nil)
        run_test(json: "{name}", keyPath: "person", expected: nil)
        run_test(json: "{\"name\": 123}", keyPath: "person", expected: nil)
        run_test(json: "{ \"name\": \"John\" }", keyPath: "person", expected: nil)
        run_test(json: "{ \"name\": \"John\", \"person\": {} }", keyPath: "person", expected: nil)

        run_test(json: "{ \"person\": { \"name\": \"John\" } }", keyPath: "person", expected: .init(name: "John"))
        run_test(json: "{ \"person\": { \"name\": \"John\" }, \"other\": 123 }", keyPath: "person", expected: .init(name: "John"))
        run_test(json: "{ \"other\": 123, \"person\": { \"name\": \"John\" }, \"other2\": 321 }", keyPath: "person", expected: .init(name: "John"))
    }

    func test_decoding_single_path() {
        run_test(json: "", keyPath: ["person"], expected: nil)
        run_test(json: "{}", keyPath: ["person"], expected: nil)
        run_test(json: "{name}", keyPath: ["person"], expected: nil)
        run_test(json: "{\"name\": 123}", keyPath: ["person"], expected: nil)
        run_test(json: "{ \"name\": \"John\" }", keyPath: ["person"], expected: nil)
        run_test(json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person"], expected: nil)

        run_test(json: "{ \"person\": { \"name\": \"John\" } }", keyPath: ["person"], expected: .init(name: "John"))
        run_test(json: "{ \"person\": { \"name\": \"John\" }, \"other\": 123 }", keyPath: ["person"], expected: .init(name: "John"))
        run_test(json: "{ \"other\": 123, \"person\": { \"name\": \"John\" }, \"other2\": 321 }", keyPath: ["person"], expected: .init(name: "John"))
    }

    func test_decoding_deep_path() {
        run_test(json: "", keyPath: ["person", "name"], expectedString: nil)
        run_test(json: "{}", keyPath: ["person", "name"], expectedString: nil)
        run_test(json: "{name}", keyPath: ["person", "name"], expectedString: nil)
        run_test(json: "{\"name\": 123}", keyPath: ["person", "name"], expectedString: nil)
        run_test(json: "{ \"name\": \"John\" }", keyPath: ["person", "name"], expectedString: nil)
        run_test(json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person", "name"], expectedString: nil)

        run_test(json: "{ \"person\": { \"name\": \"John\" } }", keyPath: ["person", "name"], expectedString: "John")
        run_test(json: "{ \"person\": { \"name\": \"John\" }, \"other\": 123 }", keyPath: ["person", "name"], expectedString: "John")
        run_test(json: "{ \"other\": 123, \"person\": { \"name\": \"John\" }, \"other2\": 321 }", keyPath: ["person", "name"], expectedString: "John")
    }

    private func run_test(json: String, keyPath: String, expected: Person?, file: StaticString = #filePath, line: UInt = #line) {
        let data = json.data(using: .utf8) ?? Data()
        XCTAssertEqual(try? data.decode(Person.self, keyPath: keyPath), expected, file: file, line: line)
    }

    private func run_test(json: String, keyPath: [String], expected: Person?, file: StaticString = #filePath, line: UInt = #line) {
        let data = json.data(using: .utf8) ?? Data()
        XCTAssertEqual(try? data.decode(Person.self, keyPath: keyPath), expected, file: file, line: line)
    }

    private func run_test(json: String, keyPath: [String], expectedString expected: String?, file: StaticString = #filePath, line: UInt = #line) {
        let data = json.data(using: .utf8) ?? Data()
        XCTAssertEqual(try? data.decode(String.self, keyPath: keyPath), expected, file: file, line: line)
    }
}
