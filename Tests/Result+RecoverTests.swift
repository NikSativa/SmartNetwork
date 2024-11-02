import Foundation
import SpryKit
import XCTest

@testable import SmartNetwork

final class Result_RecoverTests: XCTestCase {
    func test_init() throws {
        var subject: Result<Int, Error> = .success(1)
        XCTAssertEqual(try subject.recoverResult().get(), 1)

        subject = .failure(RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try subject.recoverResult().get(), RequestEncodingError.invalidJSON)

        subject = .failure(RequestDecodingError.nilResponse)
        XCTAssertEqual(try subject.recoverResult().get(), nil)

        subject = .failure(RequestDecodingError.emptyResponse)
        XCTAssertEqual(try subject.recoverResult().get(), nil)
    }
}
