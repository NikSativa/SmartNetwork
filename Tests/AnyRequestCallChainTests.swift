import Combine
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class AnyRequestCallChainTests: XCTestCase {
    private var observers: [AnyCancellable] = []
    private let url: SmartURL = .testMake(string: "http://example1.com/signin")
    private let urlNil: SmartURL = .testMake(string: "http://example1.com/nil")
    private let urlEmpty: SmartURL = .testMake(string: "http://example1.com/empty")
    private let urlOther: SmartURL = .testMake(string: "http://example1.com/other")
    private let urlComplex: SmartURL = .testMake(string: "http://example1.com/complex")

    private let requestManager: SmartRequestManager = .init()
    private let okObj = TestInfo(id: 1)
    private let okObj2 = TestInfo2(id2: 2)

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared
            .add(condition: .isAddress(url),
                 body: .encode(okObj),
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(urlNil),
                 body: nil,
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(urlEmpty),
                 body: .empty,
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(urlOther),
                 body: .encode(okObj2),
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(urlComplex),
                 body: .encode(Complex(obj1: okObj, obj2: okObj2)),
                 delayInSeconds: 0.1)
            .store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    func test_decodable() {
        // ok
        run_test(decodable(TestInfo.self)) {
            XCTAssertEqual($0, okObj, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self)) {
            XCTAssertEqual($0, okObj, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        // nil
        run_test(decodable(TestInfo.self, url: urlNil)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, url: urlNil)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, url: urlNil)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, url: urlNil)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // empty
        run_test(decodable(TestInfo.self, url: urlEmpty)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, url: urlEmpty)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, url: urlEmpty)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, url: urlEmpty)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // other
        run_test(decodable(TestInfo.self, url: urlOther)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, url: urlOther)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, url: urlOther)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, url: urlOther)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        // unknown keypath
        run_test(decodable(TestInfo.self, keyPath: ["any"], url: urlComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, keyPath: ["any"], url: urlComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, keyPath: ["any"], url: urlComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, keyPath: ["any"], url: urlComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // keypath - ok
        run_test(decodable(TestInfo.self, keyPath: ["obj1"], url: urlComplex)) {
            XCTAssertEqual($0, okObj, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, keyPath: ["obj2"], url: urlComplex)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, keyPath: ["obj1"], url: urlComplex)) {
            XCTAssertEqual($0, okObj, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, keyPath: ["obj2"], url: urlComplex)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        // keypath - exists but fail
        run_test(decodable(TestInfo.self, keyPath: ["obj2"], url: urlComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, keyPath: ["obj1"], url: urlComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, keyPath: ["obj2"], url: urlComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, keyPath: ["obj1"], url: urlComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // keypath - fail int
        run_test(decodable(Int.self, keyPath: ["obj2"], url: urlComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int.self, keyPath: ["obj1"], url: urlComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj2"], url: urlComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj1"], url: urlComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // keypath - ok int
        run_test(decodable(Int.self, keyPath: ["obj2", "id2"], url: urlComplex)) {
            XCTAssertEqual($0, .success(2), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int.self, keyPath: ["obj1", "id"], url: urlComplex)) {
            XCTAssertEqual($0, .success(1), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj2", "id2"], url: urlComplex)) {
            XCTAssertEqual($0, .success(2), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj1", "id"], url: urlComplex)) {
            XCTAssertEqual($0, .success(1), "\($0)", file: $1, line: $2)
        }
    }

    private func run_test<T>(_ requestManager: any RequestCompletion<T>,
                             expected: (T, _ file: StaticString, _ line: UInt) -> Void,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        let exp = expectation(description: "wait response \(file):\(line) \(#function)")
        let result: UnsafeValue<T> = .init()
        requestManager.complete {
            result.value = $0
            exp.fulfill()
        }
        .detach()
        .start()
        wait(for: [exp], timeout: 1)
        expected(result.value, file, line)
    }

    private func decodable<T: Decodable & Equatable>(_ type: T.Type, keyPath: DecodableKeyPath<T> = [], url: SmartURL? = nil) -> any RequestCompletion<Result<T, Error>> {
        return requestManager
            .request(url: url ?? self.url)
            .decode(type, keyPath: keyPath)
    }

    private func decodable<T>(_ type: T.Type, keyPath: DecodableKeyPath<T> = [], url: SmartURL? = nil) -> any RequestCompletion<Result<T, Error>>
    where T: Decodable & Equatable & ExpressibleByNilLiteral {
        return requestManager
            .request(url: url ?? self.url)
            .decode(type, keyPath: keyPath)
    }
}

private struct Complex: Codable {
    let obj1: TestInfo
    let obj2: TestInfo2
}
