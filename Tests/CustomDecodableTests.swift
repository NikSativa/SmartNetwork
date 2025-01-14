import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class DeserializableTests: XCTestCase {
    private lazy var image: SpryKit.Image = .spry.testImage
    private lazy var imageData: Data = image.testData()!

    private lazy var emptyData: Data = .init()
    private lazy var bodyData: Data = {
        return try! JSONSerialization.data(withJSONObject: ["id": 1], options: [.sortedKeys, .prettyPrinted])
    }()

    private lazy var bodyBrokenData: Data = {
        return "aasd".data(using: .utf8)!
    }()

    func test_data() {
        let decoder = DataContent()
        XCTAssertNil(try custom(decoder).get())
        XCTAssertEqual(try custom(decoder, body: bodyData).get(), bodyData)
        XCTAssertEqual(try custom(decoder, body: emptyData).get(), emptyData)
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(decoder, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
    }

    func test_decodable() {
        let decoder = DecodableContent<TestInfo>()
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(decoder, body: emptyData).get()
        }
        XCTAssertNil(try custom(decoder).get())
        XCTAssertEqual(try custom(decoder, body: bodyData).get(), .init(id: 1))
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(decoder, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(decoder, body: bodyBrokenData).get()) { _ in }
    }

    func test_decodable_keyPath() {
        let decoder = DecodableContent<Int>(keyPath: ["id"])
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(decoder, body: emptyData).get()
        }
        XCTAssertNil(try custom(decoder).get())
        XCTAssertEqual(try custom(decoder, body: bodyData).get(), 1)
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(decoder, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(decoder, body: bodyBrokenData).get()) { _ in }
    }

    @MainActor
    func test_image() {
        #if supportsVisionOS
        Screen.scale = 2
        #endif

        let decoder = ImageContent()
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(decoder, body: emptyData).get()
        }
        #if !supportsVisionOS
        XCTAssertEqual(try custom(decoder, body: imageData).get()?.testData().unwrap(), imageData)
        #endif
        XCTAssertNil(try custom(decoder).get())
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(decoder, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(decoder, body: bodyBrokenData).get()) { _ in }
    }

    func test_json() {
        let decoder = JSONContent()
        XCTAssertThrowsError(RequestDecodingError.emptyResponse) {
            try custom(decoder, body: emptyData).get()
        }
        XCTAssertNil(try custom(decoder).get())
        XCTAssertEqual(try custom(decoder, body: bodyData).get() as! [String: Int], ["id": 1])
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.lenghtRequired)).get(), StatusCode(.lenghtRequired))
        XCTAssertThrowsError(try custom(decoder, error: StatusCode(.badRequest)).get(), StatusCode(.badRequest))
        XCTAssertThrowsError(try custom(decoder, body: bodyData, error: RequestEncodingError.invalidJSON).get(), RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try custom(decoder, body: bodyBrokenData).get()) { _ in }
    }

    func test_void() {
        let decoder = VoidContent()
        XCTAssertTrue(custom(decoder).isSuccess == true)
        XCTAssertTrue(custom(decoder, body: bodyData).isSuccess == true)
        XCTAssertTrue(custom(decoder, body: emptyData).isSuccess == true)
        XCTAssertTrue(custom(decoder, error: StatusCode(.noContent)).isSuccess == true)
        XCTAssertTrue(custom(decoder, error: RequestDecodingError.nilResponse).isSuccess == true)

        XCTAssertTrue(custom(decoder, error: StatusCode(.multiStatus)).isSuccess == false)
        XCTAssertTrue(custom(decoder, error: StatusCode(.lenghtRequired)).isSuccess == false)
        XCTAssertTrue(custom(decoder, error: RequestDecodingError.brokenResponse).isSuccess == false)
    }

    private func custom<T: Deserializable>(_ strategy: T, body: Data? = nil, error: Error? = nil) -> Result<T.Object?, Error> {
        let result = strategy.decode(with: .testMake(url: .spry.testMake(),
                                                     statusCode: 200,
                                                     body: body.map(Body.data),
                                                     error: error),
                                     parameters: .init())
        switch result {
        case .success(let obj):
            return .success(obj)
        case .failure(RequestDecodingError.nilResponse):
            return .success(nil)
        case .failure(let error):
            return .failure(error)
        }
    }
}

private extension Result where Success == Void? {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

private extension DecodableContent {
    init() {
        self.init(decoder: nil, keyPath: [])
    }

    init(keyPath: DecodableKeyPath<Response>) {
        self.init(decoder: nil, keyPath: keyPath)
    }
}
