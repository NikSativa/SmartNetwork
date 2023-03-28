import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class CustomDecodableTests: XCTestCase {
    private lazy var image: Image = .circle
    private lazy var imageData: Data = image.pngData()!

    private lazy var bodyData: Data = {
        return try! JSONSerialization.data(withJSONObject: ["id": 1], options: [.sortedKeys, .prettyPrinted])
    }()

    private lazy var bodyBrokenData: Data = {
        return "aasd".data(using: .utf8)!
    }()

    func test_data() {
        XCTAssertNil(try custom(DataContent.self).get())
        XCTAssertEqual(try custom(DataContent.self, body: bodyData).get(), bodyData)
        XCTAssertThrowsError(try custom(DataContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(DataContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(DataContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
    }

    func test_decodable() {
        XCTAssertNil(try custom(DecodableContent<TestInfo>.self).get())
        XCTAssertEqual(try custom(DecodableContent<TestInfo>.self, body: bodyData).get(), .init(id: 1))
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, body: bodyBrokenData).get()) { _ in }
    }

    func test_image() {
        XCTAssertNil(try custom(ImageContent.self).get())
        XCTAssertEqual(try custom(ImageContent.self, body: imageData).get()?.pngData(), image.pngData())
        XCTAssertThrowsError(try custom(ImageContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(ImageContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(ImageContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(ImageContent.self, body: bodyBrokenData).get()) { _ in }
    }

    func test_json() {
        XCTAssertNil(try custom(JSONContent.self).get())
        XCTAssertEqual(try custom(JSONContent.self, body: bodyData).get() as! [String: Int], ["id": 1])
        XCTAssertThrowsError(try custom(JSONContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(JSONContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(JSONContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(JSONContent.self, body: bodyBrokenData).get()) { _ in }
    }

    func test_void() {
        XCTAssertTrue(custom(VoidContent.self).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, body: bodyData).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, error: StatusCode(.resetContent)).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, error: RequestDecodingError.nilResponse).isSuccess)

        XCTAssertFalse(custom(VoidContent.self, error: StatusCode(.lenghtRequired)).isSuccess)
        XCTAssertFalse(custom(VoidContent.self, error: RequestDecodingError.brokenResponse).isSuccess)
    }

    private func custom<T: CustomDecodable>(_ type: T.Type, body: Data? = nil, error: Error? = nil) -> Result<T.Object, Error> {
        let decodable = type.init(with: .testMake(url: .testMake(),
                                                  statusCode: 200,
                                                  body: body,
                                                  error: error),
                                  decoder: .init())
        return decodable.result
    }
}

func XCTAssertEqual(_ expression1: @autoclosure () throws -> Image,
                    _ expression2: @autoclosure () throws -> Image,
                    _ message: @autoclosure () -> String = "",
                    file: StaticString = #filePath,
                    line: UInt = #line) {}

private extension Result where Success == Void {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
