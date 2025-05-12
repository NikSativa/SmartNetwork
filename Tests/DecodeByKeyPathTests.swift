import Foundation
import SmartNetwork
import XCTest

final class DecodeByKeyPathTests: XCTestCase {
    private struct Person: Decodable, Equatable {
        let name: String
    }

    func test_decoding_single_path() throws {
        try run_test(String.self, json: "", keyPath: "person", expected: nil)
        try run_test(String.self, json: "{}", keyPath: "person", expected: nil)
        try run_test(String.self, json: "{name}", keyPath: "person", expected: nil)
        try run_test(String.self, json: "{\"name\": 123}", keyPath: "person", expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\" }", keyPath: "person", expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: "person", expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": \"abc\" }", keyPath: "person", expected: "abc")

        try run_test(Person.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: "person", expected: nil)
        try run_test(Person.self, json: "{ \"person\": { \"name\": \"John\" } }", keyPath: "person", expected: .init(name: "John"))
        try run_test(Person.self, json: "{ \"person\": { \"name\": \"John\" }, \"other\": 123 }", keyPath: "person", expected: .init(name: "John"))
        try run_test(Person.self, json: "{ \"other\": 123, \"person\": { \"name\": \"John\" }, \"other2\": 321 }", keyPath: "person", expected: .init(name: "John"))

        try run_test(Person.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: "1111/2222/3333", expected: nil)
        try run_test(Person.self, json: "{ \"name\": \"John\", \"person\": \"abc\" }", keyPath: "1111/2222/3333", expected: nil)
    }

    func test_decoding_array_path() throws {
        try run_test(String.self, json: "", keyPath: [], expected: nil)
        try run_test(String.self, json: "", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{}", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{name}", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{\"name\": 123}", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\" }", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": \"abc\" }", keyPath: ["person"], expected: "abc")

        try run_test(Person.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person"], expected: nil)
        try run_test(Person.self, json: "{ \"person\": { \"name\": \"John\" } }", keyPath: ["person"], expected: .init(name: "John"))
        try run_test(Person.self, json: "{ \"person\": { \"name\": \"John\" }, \"other\": 123 }", keyPath: ["person"], expected: .init(name: "John"))
        try run_test(Person.self, json: "{ \"other\": 123, \"person\": { \"name\": \"John\" }, \"other2\": 321 }", keyPath: ["person"], expected: .init(name: "John"))

        try run_test(Person.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["1111", "2222", "3333"], expected: nil)
        try run_test(Person.self, json: "{ \"name\": \"John\", \"person\": \"abc\" }", keyPath: ["1111", "2222", "3333"], expected: nil)
    }

    func test_decoding_deep_path() throws {
        try run_test(String.self, json: "", keyPath: [], expected: nil)
        try run_test(String.self, json: "", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{}", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{name}", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{\"name\": 123}", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\" }", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": \"abc\" }", keyPath: ["person"], expected: "abc")

        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["person", "name"], expected: nil)
        try run_test(String.self, json: "{ \"person\": { \"name\": \"John\" } }", keyPath: ["person", "name"], expected: "John")
        try run_test(String.self, json: "{ \"person\": { \"name\": \"John\" }, \"other\": 123 }", keyPath: ["person", "name"], expected: "John")
        try run_test(String.self, json: "{ \"other\": 123, \"person\": { \"name\": \"John\" }, \"other2\": 321 }", keyPath: ["person", "name"], expected: "John")

        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": {} }", keyPath: ["1111", "2222", "3333"], expected: nil)
        try run_test(String.self, json: "{ \"name\": \"John\", \"person\": \"abc\" }", keyPath: ["1111", "2222", "3333"], expected: nil)
    }

    private func run_test<T>(_ type: T.Type,
                             json: String,
                             keyPath: String,
                             expected: T?,
                             file: StaticString = #filePath,
                             line: UInt = #line) throws
    where T: Decodable & Equatable {
        let data = json.data(using: .utf8) ?? Data()
        XCTAssertEqual(try? data.decode(type, keyPath: keyPath, decoder: Bool.random() ? nil : .init()), expected, file: file, line: line)
    }

    private func run_test<T>(_ type: T.Type,
                             json: String,
                             keyPath: [String],
                             expected: T?,
                             file: StaticString = #filePath,
                             line: UInt = #line) throws
    where T: Decodable & Equatable {
        let data = json.data(using: .utf8) ?? Data()
        XCTAssertEqual(try? data.decode(type, keyPath: keyPath, decoder: Bool.random() ? nil : .init()), expected, file: file, line: line)
    }
}
