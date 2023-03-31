import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class AddressTests: XCTestCase {
    func test_extensions() {
        var actualURL: URL?

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "//some.com") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("//some.com/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "my://some.com") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("my://some.com/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "http://some.com/asd") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "http://some.com/asd") + ["endpoint1", "endpoint2"]
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint1/endpoint2"))

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "http://some.com/asd").append("endpoint")
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "http://some.com/asd").append(["endpoint1", "endpoint2"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint1/endpoint2"))

        actualURL = XCTAssertNoThrowError {
            let subject = try Address(string: "http://some.com/asd").append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd?param=value"))

        XCTAssertThrowsError(try Address(host: "").url(), RequestEncodingError.brokenAddress)

        actualURL = XCTAssertNoThrowError {
            let subject = Address(scheme: .other(""), host: "some.com", shouldRemoveSlashesForEmptyScheme: true)
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("some.com"))
    }

    func test_init() {
        XCTAssertAddress(expected: "https://some.com:11")
        XCTAssertAddress(expected: "https://some.com:11/endpoint",
                         path: ["endpoint"])
        XCTAssertAddress(expected: "https://some.com:11/endpoint1/endpoint2",
                         path: ["endpoint1", "endpoint2"])
        XCTAssertAddress(expected: "https://some.com:11?key=value",
                         queryItems: ["key": "value"])
        XCTAssertAddress(expected: "https://some.com:11?key=value&key1=value1",
                         queryItems: ["key": "value", "key1": "value1"])
        XCTAssertAddress(expected: "https://some.com:11#page",
                         fragment: "page")
        XCTAssertAddress(expected: "https://some.com:11/",
                         shouldAddSlashAfterEndpoint: true)
        XCTAssertAddress(expected: "https://some.com:11",
                         shouldAddSlashAfterEndpoint: false)
        XCTAssertAddress(expected: "https://some.com:11",
                         shouldRemoveSlashesForEmptyScheme: true)
        XCTAssertAddress(expected: "https://some.com:11",
                         shouldRemoveSlashesForEmptyScheme: false)

        XCTAssertAddress(expected: "https://some.com:11/endpoint?key=value",
                         path: ["endpoint"],
                         queryItems: ["key": "value"])
        XCTAssertAddress(expected: "https://some.com:11/endpoint?key=value&key1=value1",
                         path: ["endpoint"],
                         queryItems: ["key": "value", "key1": "value1"])
        XCTAssertAddress(expected: "https://some.com:11/endpoint?key=value#page",
                         path: ["endpoint"],
                         queryItems: ["key": "value"],
                         fragment: "page")
        XCTAssertAddress(expected: "https://some.com:11/endpoint?key=value&key1=value1#page",
                         path: ["endpoint"],
                         queryItems: ["key": "value", "key1": "value1"],
                         fragment: "page")
    }
}

private func XCTAssertAddress(expected: String,
                              path: [String] = [],
                              queryItems: QueryItems = [],
                              fragment: String? = nil,
                              shouldAddSlashAfterEndpoint: Bool = false,
                              shouldRemoveSlashesForEmptyScheme: Bool = false,
                              file: StaticString = #filePath,
                              line: UInt = #line) {
    let mainUrl = XCTAssertNoThrowError(file: file, line: line) {
        let subject = Address(scheme: .https,
                              host: "some.com",
                              port: 11,
                              path: path,
                              queryItems: queryItems,
                              fragment: fragment,
                              shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                              shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
        return try subject.url()
    }
    let expectedURL: URL = .spry.testMake(expected)
    XCTAssertEqual(mainUrl, expectedURL, mainUrl?.absoluteString ?? expected, file: file, line: line)

    let urlURL = XCTAssertNoThrowError(file: file, line: line) {
        let subject = try Address(url: expectedURL,
                                  shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                                  shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
        return try subject.url()
    }
    XCTAssertEqual(urlURL, mainUrl, file: file, line: line)

    let stringURL = XCTAssertNoThrowError(file: file, line: line) {
        let subject = try Address(string: expected,
                                  shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                                  shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
        return try subject.url()
    }
    XCTAssertEqual(stringURL, mainUrl, file: file, line: line)
}
