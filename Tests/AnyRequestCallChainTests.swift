import Combine
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class AnyRequestCallChainTests: XCTestCase {
    private var observers: [AnyCancellable] = []
    private let address: Address = .testMake(string: "http://example1.com/signin")
    private let addressNil: Address = .testMake(string: "http://example1.com/nil")
    private let addressEmpty: Address = .testMake(string: "http://example1.com/empty")
    private let addressOther: Address = .testMake(string: "http://example1.com/other")
    private let addressComplex: Address = .testMake(string: "http://example1.com/complex")

    private let requestManager: SmartRequestManager = .init()
    private let okObj = TestInfo(id: 1)
    private let okObj2 = TestInfo2(id2: 2)

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared
            .add(condition: .isAddress(address),
                 body: .encode(okObj),
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(addressNil),
                 body: nil,
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(addressEmpty),
                 body: .empty,
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(addressOther),
                 body: .encode(okObj2),
                 delayInSeconds: 0.1)
            .store(in: &observers)

        HTTPStubServer.shared
            .add(condition: .isAddress(addressComplex),
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
        run_test(decodable(TestInfo.self, address: addressNil)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, address: addressNil)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, address: addressNil)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, address: addressNil)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // empty
        run_test(decodable(TestInfo.self, address: addressEmpty)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, address: addressEmpty)) {
            XCTAssertEqual($0, RequestDecodingError.nilResponse, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, address: addressEmpty)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, address: addressEmpty)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // other
        run_test(decodable(TestInfo.self, address: addressOther)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, address: addressOther)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, address: addressOther)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, address: addressOther)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        // unknown keypath
        run_test(decodable(TestInfo.self, keyPath: ["any"], address: addressComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, keyPath: ["any"], address: addressComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, keyPath: ["any"], address: addressComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, keyPath: ["any"], address: addressComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // keypath - ok
        run_test(decodable(TestInfo.self, keyPath: ["obj1"], address: addressComplex)) {
            XCTAssertEqual($0, okObj, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, keyPath: ["obj2"], address: addressComplex)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, keyPath: ["obj1"], address: addressComplex)) {
            XCTAssertEqual($0, okObj, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, keyPath: ["obj2"], address: addressComplex)) {
            XCTAssertEqual($0, okObj2, "\($0)", file: $1, line: $2)
        }

        // keypath - exists but fail
        run_test(decodable(TestInfo.self, keyPath: ["obj2"], address: addressComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2.self, keyPath: ["obj1"], address: addressComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo?.self, keyPath: ["obj2"], address: addressComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(TestInfo2?.self, keyPath: ["obj1"], address: addressComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // keypath - fail int
        run_test(decodable(Int.self, keyPath: ["obj2"], address: addressComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int.self, keyPath: ["obj1"], address: addressComplex)) {
            XCTAssertTrue($0.error is DecodingError, "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj2"], address: addressComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj1"], address: addressComplex)) {
            XCTAssertEqual($0, .success(nil), "\($0)", file: $1, line: $2)
        }

        // keypath - ok int
        run_test(decodable(Int.self, keyPath: ["obj2", "id2"], address: addressComplex)) {
            XCTAssertEqual($0, .success(2), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int.self, keyPath: ["obj1", "id"], address: addressComplex)) {
            XCTAssertEqual($0, .success(1), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj2", "id2"], address: addressComplex)) {
            XCTAssertEqual($0, .success(2), "\($0)", file: $1, line: $2)
        }

        run_test(decodable(Int?.self, keyPath: ["obj1", "id"], address: addressComplex)) {
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

    private func decodable<T>(_ type: T.Type, keyPath: DecodableKeyPath<T> = [], address: Address? = nil) -> any RequestCompletion<Result<T, Error>>
    where T: Decodable & Equatable {
        return requestManager
            .request(address: address ?? self.address)
            .decode(type, keyPath: keyPath)
    }

    private func decodable<T>(_ type: T.Type, keyPath: DecodableKeyPath<T> = [], address: Address? = nil) -> any RequestCompletion<Result<T, Error>>
    where T: Decodable & Equatable & ExpressibleByNilLiteral {
        return requestManager
            .request(address: address ?? self.address)
            .decode(type, keyPath: keyPath)
    }
}

private struct Complex: Codable {
    let obj1: TestInfo
    let obj2: TestInfo2
}
