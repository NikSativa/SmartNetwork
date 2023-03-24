import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class AddressTests: XCTestCase {
    func test_url() {
        var subject: Address
        var expected: URL?

        subject = .url(.testMake("some.com"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("some.com"))

        subject = .url(.testMake("some.com"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("some.com"))

        subject = .url(.testMake("https://some.com/asd"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com/asd"))

        subject = .url(.testMake("https://some.com/asd"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com/asd"))

        subject = .url(.testMake("http://some.com"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("http://some.com"))

        subject = .url(.testMake("http://some.com"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("http://some.com"))

        subject = .url(.testMake("https://some.com"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com"))

        subject = .url(.testMake("https://some.com"))
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com"))

        subject = .url(.testMake("some.com/item=value/endpoint/?item=value"))
        XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))

        subject = .url(.testMake("some.com/item=value/endpoint/?item=value"))
        XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
    }

    func test_init() {
        var subject: Address
        var expected: URL?

        subject = .address(host: "some.com")
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com"))

        subject = .address(host: "some.com")
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com"))

        subject = .address(host: "some.com", endpoint: "endpoint")
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint"))

        subject = .address(host: "some.com", endpoint: "endpoint")
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint"))

        subject = .address(host: "some.com", endpoint: "/endpoint/")
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint"))

        subject = .address(host: "some.com", endpoint: "/endpoint/")
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint"))

        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint/?item=value"))

        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint?item=value"))

        subject = .address(host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint/?item=value"))

        subject = .address(host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        expected = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(expected, .testMake("https://some.com/endpoint?item=value"))

        subject = .address(host: "\"some.com")
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true), EncodingError.lackAdress)

        subject = .address(host: "\"some.com")
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false), EncodingError.lackAdress)

        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true), EncodingError.lackAdress)

        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false), EncodingError.lackAdress)
    }
}
