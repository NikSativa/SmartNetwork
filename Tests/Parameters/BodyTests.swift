import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class BodyTests: XCTestCase {
    var request: URLRequest!

    override func setUp() {
        super.setUp()
        request = .spry.testMake(url: "some.com")
    }

    override func tearDown() {
        super.tearDown()
        request = nil
    }

    func test_empty() {
        XCTAssertNoThrowError(try Body.empty.fill(&request, encoder: .init()))
        XCTAssertNil(request.httpBody)
    }

    func test_data() throws {
        let data = "str".data(using: .utf8).unsafelyUnwrapped
        XCTAssertNoThrowError(try Body.data(data).fill(&request, encoder: .init()))
        XCTAssertEqual(request.httpBody, data)
    }

    #if !os(visionOS)
    func test_image_png() {
        let image = Image.spry.testImage
        XCTAssertNoThrowError(try Body.image(.png(image)).fill(&request, encoder: .init()))
        XCTAssertEqual(request.httpBody, image.testData())
    }
    #endif

    #if !os(macOS)
    func test_image_jpeg() {
        let image = Image.spry.testImage
        XCTAssertNoThrowError(try Body.image(.jpeg(image, compressionQuality: 1)).fill(&request, encoder: .init()))
        XCTAssertEqual(request.httpBody, image.jpegData(compressionQuality: 1))
    }
    #endif

    func test_encodable() {
        let info = TestInfo(id: 1)
        XCTAssertNoThrowError(try Body.encodable(info).fill(&request, encoder: .init()))
        XCTAssertEqual(request.httpBody?.info(), info)

        XCTAssertNoThrowError(try Body.encodable(info).fill(&request, encoder: .init()))
        XCTAssertEqual(request.httpBody?.info(), info)

        XCTAssertThrowsError(try Body.encodable(BrokenTestInfo(id: 1)).fill(&request, encoder: .init()), RequestEncodingError.invalidJSON)
    }

    func test_form() {
        let data = "str".data(using: .utf8).unsafelyUnwrapped
        let info = Body.Form(parameters: ["param": "value"],
                             boundary: "<<-->>",
                             mimeType: .binary,
                             name: .file,
                             fileName: "fileName",
                             data: data)
        XCTAssertNoThrowError(try Body.form(info).fill(&request, encoder: .init()))
        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "--<<-->>\r\nContent-Disposition: form-data; name=\"param\"\r\n\r\nvalue\r\n--<<-->>\r\nContent-Disposition: form-data; name=\"file\"; filename=\"fileName\"\r\nContent-Type: application/x-binary\r\n\r\nstr\r\n--<<-->>--\r\n"
        XCTAssertEqual(text, expected)
    }

    func test_xform() {
        let info: [String: Any] = [
            "param": "value",
            "param1": 1,
            "param2": BrokenTestInfo(id: 2)
        ]
        XCTAssertNoThrowError(try Body.xform(info).fill(&request, encoder: .init()))
        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "param2=BrokenTestInfo%28id%3A+2%29&param=value&param1=1"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())
    }

    func test_xform_encodable() {
        let info = TestInfo2(id: 1, id2: 2, id3: 3)
        XCTAssertNoThrowError(try Body.xform(info, encoder: .init()).fill(&request, encoder: .init()))

        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "id=1&id3=3&id2=2"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())

        XCTAssertThrowsError(try Body.xform(BrokenTestInfo(id: 1), encoder: .init()).fill(&request, encoder: .init()), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.xform([1, 2], encoder: .init()).fill(&request, encoder: .init()), RequestEncodingError.invalidJSON)
        XCTAssertNoThrowError(try Body.xform([11: "2"], encoder: .init()).fill(&request, encoder: .init()))
    }
}

private struct TestInfo2: Codable, Equatable {
    let id: Int
    let id2: Int
    let id3: Int
}
