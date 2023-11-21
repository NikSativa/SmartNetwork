import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class CustomDecodableTests: XCTestCase {
    private lazy var image: NSpry.Image = .spry.testImage
    private lazy var imageData: Data = image.testData()!

    private lazy var emptyData: Data = .init()
    private lazy var bodyData: Data = {
        return try! JSONSerialization.data(withJSONObject: ["id": 1], options: [.sortedKeys, .prettyPrinted])
    }()

    private lazy var bodyBrokenData: Data = {
        return "aasd".data(using: .utf8)!
    }()

    func test_data() {
        XCTAssertNil(try custom(OptionalDataContent.self).get())
        XCTAssertEqual(try custom(OptionalDataContent.self, body: bodyData).get(), bodyData)
        XCTAssertEqual(try custom(OptionalDataContent.self, body: emptyData).get(), emptyData)
        XCTAssertThrowsError(try custom(OptionalDataContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(OptionalDataContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(OptionalDataContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)

        XCTAssertThrowsError(RequestDecodingError.nilResponse) {
            try custom(DataContent.self).get()
        }
        XCTAssertEqual(try custom(DataContent.self, body: bodyData).get(), bodyData)
        XCTAssertEqual(try custom(DataContent.self, body: emptyData).get(), emptyData)
        XCTAssertThrowsError(try custom(DataContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(DataContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(DataContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
    }

    func test_decodable() {
        XCTAssertNil(try custom(OptionalDecodableContent<TestInfo>.self).get())
        XCTAssertEqual(try custom(OptionalDecodableContent<TestInfo>.self, body: bodyData).get(), .init(id: 1))
        XCTAssertThrowsError(try custom(OptionalDecodableContent<TestInfo>.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(OptionalDecodableContent<TestInfo>.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(OptionalDecodableContent<TestInfo>.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(OptionalDecodableContent<TestInfo>.self, body: bodyBrokenData).get()) { _ in }

        XCTAssertThrowsError(RequestDecodingError.nilResponse) {
            try custom(DecodableContent<TestInfo>.self).get()
        }
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(DecodableContent<TestInfo>.self, body: emptyData).get()
        }
        XCTAssertEqual(try custom(DecodableContent<TestInfo>.self, body: bodyData).get(), .init(id: 1))
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(DecodableContent<TestInfo>.self, body: bodyBrokenData).get()) { _ in }
    }

    func test_image() {
        XCTAssertNil(try custom(OptionalImageContent.self).get())
        XCTAssertEqual(try custom(OptionalImageContent.self, body: imageData).get()?.testData().unwrap(), imageData)
        XCTAssertThrowsError(try custom(OptionalImageContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(OptionalImageContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(OptionalImageContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(OptionalImageContent.self, body: bodyBrokenData).get()) { _ in }

        XCTAssertThrowsError(RequestDecodingError.nilResponse) {
            try custom(ImageContent.self).get()
        }
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(ImageContent.self, body: emptyData).get()
        }
        XCTAssertEqual(try custom(ImageContent.self, body: imageData).get().testData().unwrap(), imageData)
        XCTAssertThrowsError(try custom(ImageContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(ImageContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(ImageContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(ImageContent.self, body: bodyBrokenData).get()) { _ in }
    }

    func test_json() {
        XCTAssertNil(try custom(OptionalJSONContent.self).get())
        XCTAssertNil(try custom(OptionalJSONContent.self, body: nil).get())
        XCTAssertEqual(try custom(OptionalJSONContent.self, body: bodyData).get() as! [String: Int], ["id": 1])
        XCTAssertThrowsError(try custom(OptionalJSONContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(OptionalJSONContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(OptionalJSONContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(OptionalJSONContent.self, body: bodyBrokenData).get()) { _ in }

        XCTAssertThrowsError(RequestDecodingError.nilResponse) {
            try custom(JSONContent.self).get()
        }
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(JSONContent.self, body: emptyData).get()
        }
        XCTAssertEqual(try custom(JSONContent.self, body: bodyData).get() as! [String: Int], ["id": 1])
        XCTAssertThrowsError(try custom(JSONContent.self, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(JSONContent.self, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(JSONContent.self, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(JSONContent.self, body: bodyBrokenData).get()) { _ in }
    }

    func test_void() {
        XCTAssertTrue(custom(VoidContent.self).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, body: bodyData).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, body: emptyData).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, error: StatusCode(.noContent)).isSuccess)
        XCTAssertTrue(custom(VoidContent.self, error: RequestDecodingError.nilResponse).isSuccess)

        XCTAssertFalse(custom(VoidContent.self, error: StatusCode(.multiStatus)).isSuccess)
        XCTAssertFalse(custom(VoidContent.self, error: StatusCode(.lenghtRequired)).isSuccess)
        XCTAssertFalse(custom(VoidContent.self, error: RequestDecodingError.brokenResponse).isSuccess)
    }

    private func custom<T: CustomDecodable>(_ type: T.Type, body: Data? = nil, error: Error? = nil) -> Result<T.Object, Error> {
        let result = type.decode(with: .testMake(url: .spry.testMake(),
                                                 statusCode: 200,
                                                 body: body,
                                                 error: error),
                                 decoder: .init())
        return result
    }
}

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
