import Foundation
import SpryKit
import XCTest
@testable import SmartNetwork

final class AddressDetailsTests: XCTestCase {
    func test_extensions() {
        var actualURL: URL?

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents(string: "//some.com") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("some.com/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents(string: "http://localhost:50000") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://localhost:50000/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("my://some.com") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("my://some.com/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("http://some.com/asd") + "endpoint"
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("http://some.com/asd") + ["endpoint1", "endpoint2"]
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint1/endpoint2"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("http://some.com/asd").append("endpoint")
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("http://some.com/asd").append(["endpoint1", "endpoint2"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd/endpoint1/endpoint2"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("http://some.com/asd").append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://some.com/asd?param=value"))

        XCTAssertThrowsError(try SmartUrlComponents(host: "").url(), RequestEncodingError.brokenAddress)

        actualURL = XCTAssertNoThrowError {
            let subject = SmartUrlComponents(scheme: .other(""), host: "some.com")
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("some.com"))

        actualURL = XCTAssertNoThrowError {
            let subject = SmartUrlComponents(scheme: nil, host: "some.com")
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("some.com"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents("http://www.some.com/asd").append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let subject = SmartUrlComponents(scheme: .http, host: "www.some.com", path: ["asd"]).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let subject = SmartUrlComponents(scheme: .http, host: "www.some.com", path: ["asd"]).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents(url: .spry.testMake("http://www.some.com/asd")).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let subject = try SmartUrlComponents(url: .spry.testMake("http://www.some.com/asd")).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let components = URLComponents(string: "http://www.some.com/asd")!
            let subject = try SmartUrlComponents(components: components).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let components = URLComponents(string: "https://www.some.com/asd")!
            let subject = try SmartUrlComponents(components: components).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("https://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let components = URLComponents(string: "abc://www.some.com/asd")!
            let subject = try SmartUrlComponents(components: components).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("abc://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let components = URLComponents(string: "http://www.some.com/asd?param:value")!
            let subject = try SmartUrlComponents(components: components)
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param:value"))

        actualURL = XCTAssertNoThrowError {
            let subject = SmartUrlComponents(scheme: .http, host: "www.some.com", path: ["asd"]).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("http://www.some.com/asd?param=value"))

        actualURL = XCTAssertNoThrowError {
            let subject = SmartUrlComponents(scheme: "abc", host: "www.some.com", path: ["asd"], queryItems: ["some": nil]).append(["param": "value"])
            return try subject.url()
        }
        XCTAssertEqual(actualURL, .spry.testMake("abc://www.some.com/asd?some&param=value"))
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
                              queryItems: QueryItems = [:],
                              fragment: String? = nil,
                              shouldAddSlashAfterEndpoint: Bool = false,
                              shouldRemoveSlashesForEmptyScheme: Bool = false,
                              file: StaticString = #filePath,
                              line: UInt = #line) {
    let components = SmartUrlComponents(scheme: .https,
                                        host: "some.com",
                                        port: 11,
                                        path: path,
                                        queryItems: queryItems,
                                        fragment: fragment)
    let subject = SmartURL.components(components,
                                      shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint,
                                      shouldRemoveSlashesForEmptyScheme: shouldRemoveSlashesForEmptyScheme)
    let mainUrl = XCTAssertNoThrowError(file: file, line: line) {
        return try subject.url()
    }
    let expectedURL: URL = .spry.testMake(expected)
    XCTAssertEqual(mainUrl, expectedURL, mainUrl?.absoluteString ?? expected, file: file, line: line)

    let urlURL = XCTAssertNoThrowError(file: file, line: line) {
        let subject = SmartURL.url(expectedURL)
        return try subject.url()
    }
    XCTAssertEqual(urlURL, mainUrl, file: file, line: line)

    let stringURL = XCTAssertNoThrowError(file: file, line: line) {
        let subject = SmartURL(expected)
        return try subject.url()
    }
    XCTAssertEqual(stringURL, mainUrl, file: file, line: line)

    XCTAssertEqual(subject.description, expected, file: file, line: line)
    XCTAssertEqual(subject.debugDescription, expected, file: file, line: line)

    if queryItems.isEmpty, !shouldAddSlashAfterEndpoint, !shouldRemoveSlashesForEmptyScheme {
        XCTAssertEqual(components.description, expected, file: file, line: line)
        XCTAssertEqual(components.debugDescription, expected, file: file, line: line)
    }
}

internal extension SmartUrlComponents {
    func url() throws -> URL {
        return try url(shouldAddSlashAfterEndpoint: false, shouldRemoveSlashesForEmptyScheme: true)
    }

    init(_ string: String) throws {
        self = try SmartUrlComponents(string: string)
    }
}
