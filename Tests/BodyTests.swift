import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class BodyTests: XCTestCase {
    var request: URLRequest!

    override func setUp() {
        super.setUp()
        request = .testMake(url: "some.com")
    }

    override func tearDown() {
        super.tearDown()
        request = nil
    }

    func test_empty() {
        XCTAssertNotThrowsError(try Body.empty.fill(&request, isLoggingEnabled: true, encoder: .init()))
        XCTAssertNil(request.httpBody)
    }

    func test_data() throws {
        let data = "str".data(using: .utf8).unsafelyUnwrapped
        XCTAssertNotThrowsError(try Body.data(data).fill(&request, isLoggingEnabled: true, encoder: .init()))
        XCTAssertEqual(request.httpBody, data)
    }

    func test_image_png() {
        let image = Image.circle
        XCTAssertNotThrowsError(try Body.image(.png(image)).fill(&request, isLoggingEnabled: true, encoder: .init()))
        XCTAssertEqual(request.httpBody, image.pngData())
    }

    #if !os(macOS)
    func test_image_jpeg() {
        let image = Image.circle
        XCTAssertNotThrowsError(try Body.image(.jpeg(image, compressionQuality: 1)).fill(&request, isLoggingEnabled: true, encoder: .init()))
        XCTAssertEqual(request.httpBody, image.jpegData(compressionQuality: 1))
    }
    #endif

    func test_encodable() {
        Logger.logger = { text, _, _, _ in print(text) }

        let info = TestInfo(id: 1)
        XCTAssertNotThrowsError(try Body.encodable(info).fill(&request, isLoggingEnabled: true, encoder: .init()))
        XCTAssertEqual(request.httpBody?.info(), info)

        XCTAssertNotThrowsError(try Body.encodable(info).fill(&request, isLoggingEnabled: false, encoder: .init()))
        XCTAssertEqual(request.httpBody?.info(), info)

        XCTAssertThrowsError(try Body.encodable(BrokenTestInfo(id: 1)).fill(&request, isLoggingEnabled: false, encoder: .init()), RequestEncodingError.invalidJSON)
    }

    func test_form() {
        let data = "str".data(using: .utf8).unsafelyUnwrapped
        let info = Body.Form(parameters: ["param": "value"],
                             boundary: "<<-->>",
                             mimeType: .binary,
                             name: .file,
                             fileName: "fileName",
                             data: data)
        XCTAssertNotThrowsError(try Body.form(info).fill(&request, isLoggingEnabled: true, encoder: .init()))
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
        XCTAssertNotThrowsError(try Body.xform(info).fill(&request, isLoggingEnabled: true, encoder: .init()))
        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "param2=BrokenTestInfo%28id%3A+2%29&param=value&param1=1"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())
    }

    func test_xform_encodable() {
        let info = TestInfo2(id: 1, id2: 2, id3: 3)
        XCTAssertNotThrowsError(try Body.xform(info, encoder: .init()).fill(&request, isLoggingEnabled: true, encoder: .init()))
        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "id=1&id3=3&id2=2"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())

        XCTAssertThrowsError(try Body.xform(BrokenTestInfo(id: 1), encoder: .init()).fill(&request, isLoggingEnabled: false, encoder: .init()), RequestEncodingError.invalidJSON)
    }
}

private struct TestInfo2: Codable, Equatable {
    let id: Int
    let id2: Int
    let id3: Int
}
