import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class AddressTests: XCTestCase {
    func test_url() {
        var subject: Address
        var actualURL: URL?

        subject = .url(.testMake("some.com"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("some.com"))

        subject = .url(.testMake("some.com"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("some.com"))

        subject = .url(.testMake("https://some.com/asd"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com/asd"))

        subject = .url(.testMake("https://some.com/asd"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com/asd"))

        subject = .url(.testMake("http://some.com"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("http://some.com"))

        subject = .url(.testMake("http://some.com"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("http://some.com"))

        subject = .url(.testMake("https://some.com"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com"))

        subject = .url(.testMake("https://some.com"))
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com"))

        subject = .url(.testMake("some.com/item=value/endpoint/?item=value"))
        XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))

        subject = .url(.testMake("some.com/item=value/endpoint/?item=value"))
        XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
    }

    func test_init() {
        var subject: Address
        var actualURL: URL?

        subject = .address(host: "some.com")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com/"))

        subject = .address(host: "some.com")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com"))

        subject = .address(host: "some.com", endpoint: "endpoint")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint/"))

        subject = .address(host: "some.com", endpoint: "endpoint")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint"))

        subject = .address(host: "some.com", endpoint: "/endpoint/")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint/"))

        subject = .address(host: "some.com", endpoint: "/endpoint/")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint"))

        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint/?item=value"))

        subject = .address(host: "some.com", endpoint: "endpoint", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint?item=value"))

        subject = .address(host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint/?item=value"))

        subject = .address(host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint?item=value"))

        subject = .address(scheme: .other("my"), host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("my://some.com/endpoint?item=value"))

        subject = .address(scheme: .http, host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("http://some.com/endpoint?item=value"))

        subject = .address(scheme: .https, host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false))
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint?item=value"))

        subject = .address(scheme: nil, host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"])
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false, shouldRemoveSlashesBeforeEmptyScheme: true))
        XCTAssertEqual(actualURL, .testMake("some.com/endpoint?item=value"))

        subject = .address(scheme: nil, host: "some.com", endpoint: "/endpoint/", queryItems: ["item": "value"], fragment: "fr")
        actualURL = XCTAssertNotThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false, shouldRemoveSlashesBeforeEmptyScheme: true))
        XCTAssertEqual(actualURL, .testMake("some.com/endpoint?item=value#fr"))

        subject = .address(host: "\"some.com")
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true), RequestEncodingError.lackAdress)

        subject = .address(scheme: nil, host: "\"some.com")
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true), RequestEncodingError.lackAdress)

        subject = .address(host: "\"some.com")
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false), RequestEncodingError.lackAdress)

        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: true), RequestEncodingError.lackAdress)

        subject = .address(host: "some.com/item=value", endpoint: "/endpoint/", queryItems: ["item": "value"])
        XCTAssertThrowsError(try subject.url(shouldAddSlashAfterEndpoint: false), RequestEncodingError.lackAdress)
    }

    func test_append() {
        append(to: .address(host: "some.com"), name: ".address")
        append(to: .url(.testMake("https://some.com")), name: ".url")
    }

    private func append(to subject: Address,
                        name: String,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        var actualURL = XCTAssertNotThrowsError(try subject.url())
        XCTAssertEqual(actualURL, .testMake("https://some.com"), name)

        var subject1 = subject
        subject1 = subject1 + "endpoint"
        actualURL = XCTAssertNotThrowsError(try subject1.url())
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint"), name)

        var subject2 = subject
        subject2 = subject2.append("endpoint")
        actualURL = XCTAssertNotThrowsError(try subject2.url())
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint"), name)

        var subject3 = subject
        subject3 = subject3.append(["endpoint", "endpoint"])
        actualURL = XCTAssertNotThrowsError(try subject3.url())
        XCTAssertEqual(actualURL, .testMake("https://some.com/endpoint/endpoint"), name)

        var subject4 = subject
        subject4 = subject4 + ["param": "value"]
        actualURL = XCTAssertNotThrowsError(try subject4.url())
        XCTAssertEqual(actualURL, .testMake("https://some.com?param=value"), name)

        var subject5 = subject
        subject5 = subject5.append(["param": "value"])
        actualURL = XCTAssertNotThrowsError(try subject5.url())
        XCTAssertEqual(actualURL, .testMake("https://some.com?param=value"), name)
    }
}
