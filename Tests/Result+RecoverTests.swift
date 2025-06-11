import Foundation
import SpryKit
import XCTest
@testable import SmartNetwork

final class Result_RecoverTests: XCTestCase {
    func test_recoverResult() throws {
        var subject: Result<Int?, Error> = .success(1)
        XCTAssertEqual(try subject.recoverResult().get(), 1)

        subject = .failure(RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try subject.recoverResult().get(), RequestEncodingError.invalidJSON)

        subject = .failure(RequestDecodingError.nilResponse)
        XCTAssertEqual(try subject.recoverResult().get(), nil)

        subject = .failure(RequestDecodingError.emptyResponse)
        XCTAssertEqual(try subject.recoverResult().get(), nil)
    }

    func test_recoverStrongResult_with_defaultValue() throws {
        var subject: Result<Int, Error> = .success(1)
        XCTAssertEqual(try subject.recoverResult().get(), 1)

        subject = .failure(RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try subject.recoverResult().get(), RequestEncodingError.invalidJSON)

        subject = .failure(RequestDecodingError.nilResponse)
        XCTAssertEqual(try subject.recoverResult().get(), nil)

        subject = .failure(RequestDecodingError.emptyResponse)
        XCTAssertEqual(try subject.recoverResult().get(), nil)
    }

    func test_recoverResult_with_defaultValue() throws {
        var subject: Result<Int, Error> = .success(1)
        XCTAssertEqual(try subject.recoverResult(2).get(), 1)

        subject = .failure(RequestEncodingError.invalidJSON)
        XCTAssertThrowsError(try subject.recoverResult(2).get(), RequestEncodingError.invalidJSON)

        subject = .failure(RequestDecodingError.nilResponse)
        XCTAssertEqual(try subject.recoverResult(11).get(), 11)

        subject = .failure(RequestDecodingError.emptyResponse)
        XCTAssertEqual(try subject.recoverResult(11).get(), 11)
    }
}
