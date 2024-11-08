import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

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

    func test_nil() {
        XCTAssertNoThrowError(try Body?.none.fill(&request))
        XCTAssertNil(request.httpBody)
    }

    func test_empty() {
        XCTAssertNoThrowError(try Body.empty.fill(&request))
        XCTAssertEqual(request.httpBody, Data())
    }

    func test_data() throws {
        let data = "str".data(using: .utf8).unsafelyUnwrapped
        XCTAssertNoThrowError(try Body.data(data).fill(&request))
        XCTAssertEqual(request.httpBody, data)
    }

    #if !supportsVisionOS
    func test_image_png() {
        let image = Image.spry.testImage
        XCTAssertNoThrowError(try Body.image(.png(image)).fill(&request))
        XCTAssertEqual(request.httpBody, image.testData())
    }
    #endif

    #if !os(macOS)
    func test_image_jpeg() {
        let image = Image.spry.testImage
        XCTAssertNoThrowError(try Body.image(.jpeg(image, compressionQuality: 1)).fill(&request))
        XCTAssertEqual(request.httpBody, image.jpegData(compressionQuality: 1))
    }
    #endif

    func test_encodable() {
        let info = TestInfo(id: 1)
        XCTAssertNoThrowError(try Body.encode(info).fill(&request))
        XCTAssertEqual(request.httpBody?.info(), info)

        XCTAssertThrowsError(try Body.encode(BrokenTestInfo(id: 1)).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.encode(BrokenTestInfo(id: 1), with: .init()).fill(&request), RequestEncodingError.invalidJSON)
    }

    func test_json() {
        let info = TestInfo(id: 1)
        XCTAssertNoThrowError(try Body.json(["id": 1], options: [.sortedKeys]).fill(&request))
        XCTAssertEqual(request.httpBody?.info(), info)

        XCTAssertNoThrowError(try Body.json([], options: []).fill(&request))
        XCTAssertNotNil(request.httpBody)
        XCTAssertNil(request.httpBody?.info())

        XCTAssertNoThrowError(try Body.json([:], options: []).fill(&request))
        XCTAssertNotNil(request.httpBody)
        XCTAssertNil(request.httpBody?.info())

        XCTAssertThrowsError(try Body.json(1, options: []).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.json("info", options: []).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.json(info, options: []).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.json(["id": info], options: []).fill(&request), RequestEncodingError.invalidJSON)
    }

    func test_form() {
        let data = "str".data(using: .utf8).unsafelyUnwrapped
        let info = Body.MultipartForm(boundary: "<<-->>", parts: [
            .init(name: "param", data: "value".data(using: .utf8) ?? Data()),
            .init(name: .file, fileName: "fileName", mimeType: .binary, data: data)
        ])
        XCTAssertNoThrowError(try Body.form(info).fill(&request))
        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "--<<-->>\r\nContent-Disposition: form-data; name=\"param\"\r\n\r\nvalue\r\n--<<-->>\r\nContent-Disposition: form-data; name=\"file\"; filename=\"fileName\"\r\nContent-Type: application/x-binary\r\n\r\nstr\r\n--<<-->>--\r\n"
        XCTAssertEqual(text, expected)

        XCTAssertNotEqual(Body.MultipartForm.Boundary.generateRandom(), Body.MultipartForm.Boundary.generateRandom())
        XCTAssertTrue(Body.MultipartForm.Boundary.generateRandom().rawValue.hasPrefix("smartnetwork.boundary."))

        XCTAssertTrue(Body.MultipartForm.Boundary.partial("myname", hasRandomLastPart: true).rawValue.hasPrefix("myname.boundary."))
        XCTAssertTrue(Body.MultipartForm.Boundary.partial("myname", hasRandomLastPart: false).rawValue == "myname.boundary")

        XCTAssertTrue(Body.MultipartForm.Boundary.full(["myname", "boundary2"], hasRandomLastPart: true).rawValue.hasPrefix("myname.boundary2."))
        XCTAssertTrue(Body.MultipartForm.Boundary.full(["myname", "boundary2"], hasRandomLastPart: false).rawValue == "myname.boundary2")
    }

    func test_xform() {
        let info: [String: Any] = [
            "param": "value",
            "param1": 1,
            "param2": BrokenTestInfo(id: 2)
        ]
        XCTAssertNoThrowError(try Body.xform(info).fill(&request))
        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "param2=BrokenTestInfo%28id%3A+2%29&param=value&param1=1"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())
    }

    func test_xform_encodable_and_encoder() {
        let info = TestBody(id: 1, id2: 2, id3: 3)
        XCTAssertNoThrowError(try Body.xform(info, encoder: .init()).fill(&request))

        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "id=1&id3=3&id2=2"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())

        XCTAssertThrowsError(try Body.xform(BrokenTestInfo(id: 1), encoder: .init()).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.xform([1, 2], encoder: .init()).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertNoThrowError(try Body.xform([11: "2"], encoder: .init()).fill(&request))
    }

    func test_xform_encodable_without_encoder() {
        let info = TestBody(id: 1, id2: 2, id3: 3)
        XCTAssertNoThrowError(try Body.xform(info).fill(&request))

        let text = request.httpBody.flatMap {
            return String(data: $0, encoding: .utf8)
        }
        let expected = "id=1&id3=3&id2=2"
        XCTAssertEqual(text?.components(separatedBy: "&").sorted(), expected.components(separatedBy: "&").sorted())

        XCTAssertThrowsError(try Body.xform(BrokenTestInfo(id: 1), encoder: .init()).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try Body.xform([1, 2], encoder: .init()).fill(&request), RequestEncodingError.invalidJSON)
        XCTAssertNoThrowError(try Body.xform([11: "2"], encoder: .init()).fill(&request))
    }
}

private struct TestBody: Codable, Equatable {
    let id: Int
    let id2: Int
    let id3: Int
}

private extension Body {
    func fill(_ tempRequest: inout URLRequest) throws {
        let opt: Self? = self
        try opt.fill(&tempRequest)
    }
}
