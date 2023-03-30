import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class URLRepresentationTests: XCTestCase {
    func test_init() {
        var subject: Address
        var actualURL: URL?

        let representation: URLRepresentation = .init(host: "some.com").append("endpoint").append(["param": "value"])
        subject = .address(representation)
        actualURL = XCTAssertNoThrowError(try subject.url())
        XCTAssertEqual(actualURL, .spry.testMake("https://some.com/endpoint?param=value"))

        let representation2: URLRepresentation = .init(url: .spry.testMake("some.com"))
        subject = .address(representation2)
        XCTAssertThrowsError(try subject.url(), RequestEncodingError.lackAdress)
    }
}
