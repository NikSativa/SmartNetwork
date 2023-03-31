import Combine
import Foundation
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestManageringTests: XCTestCase {
    private let timoutInSeconds: TimeInterval = 0.1
    private let host = "example1.com"
    private let address: Address = .testMake(string: "http://example1.com/signin")

    private let hostImage = "example2.com"
    private let addressImage: Address = .testMake(string: "http://example2.com/signin")

    private let testObj = TestInfo(id: 1)
    private let testImage = Image.spry.testImage

    private let subject = RequestManager.create()
    private var observers: [AnyCancellable] = []
    private var exps: [XCTestExpectation] = []

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared.add(condition: .isHost(host),
                                  body: .encodable(testObj)).store(in: &observers)
        HTTPStubServer.shared.add(condition: .isHost(hostImage),
                                  body: .data(testImage.testData()!)).store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
        exps = []
    }

    // MARK: - closures

    func test_requestResult() {
        var result: [RequestResult] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.request(address: address) { [exp] in
            result.append($0)
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 2 result")
        exps.append(exp)
        subject.request(address: address, with: .testMake()) { [exp] in
            result.append($0)
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)

        let bodies = result.map {
            return $0.body?.info()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    func test_customDecodable() {
        var result: [TestInfo?] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestCustomDecodable(DecodableContent<TestInfo>.self,
                                       address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestCustomDecodable(DecodableContent<TestInfo>.self,
                                       address: address,
                                       with: .testMake()) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)
        XCTAssertEqual(result, .init(repeating: testObj, count: result.count))
    }

    func test_void() {
        var result: [Void?] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestVoid(address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 2 result")
        exps.append(exp)
        subject.requestVoid(address: address, with: .testMake()) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)
        XCTAssertEqual(result.count, result.count)
    }

    func test_decodable() {
        var result: [TestInfo?] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestDecodable(TestInfo.self,
                                 address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 2 result")
        exps.append(exp)
        subject.requestOptionalDecodable(TestInfo.self, address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)
        XCTAssertEqual(result, .init(repeating: testObj, count: result.count))
    }

    func test_image() {
        var result: [Image?] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestImage(address: addressImage) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 2 result")
        exps.append(exp)
        subject.requestOptionalImage(address: addressImage) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)
        for image in result {
            XCTAssertEqual(image?.testData(), testImage.testData())
        }
    }

    func test_data() {
        var result: [Data?] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestData(address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 2 result")
        exps.append(exp)
        subject.requestOptionalData(address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)

        let bodies = result.map {
            return $0?.info()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    func test_json() {
        var result: [Any?] = []

        var exp = expectation(description: "should return 1 result")
        exps.append(exp)
        subject.requestAny(address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        exp = expectation(description: "should return 2 result")
        exps.append(exp)
        subject.requestOptionalAny(address: address) { [exp] in
            result.append(try! $0.get())
            print(exp.description)
            exp.fulfill()
        }.deferredStart().store(in: &observers)

        wait(for: exps, timeout: timoutInSeconds)

        let bodies: [TestInfo?] = result.map {
            let data: Data? = $0.flatMap {
                return try? JSONSerialization.data(withJSONObject: $0)
            }
            return data?.info()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    // MARK: - async

    func test_requestResult() async throws {
        let result: [RequestResult] = await [
            subject.request(address: address),
            subject.request(address: address, with: .testMake())
        ]

        let bodies = result.map {
            return $0.body?.info()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    func test_customDecodable() async throws {
        let result: [Result<TestInfo?, Error>] = await [
            subject.requestCustomDecodable(DecodableContent<TestInfo>.self, address: address),
            subject.requestCustomDecodable(DecodableContent<TestInfo>.self, address: address, with: .testMake())
        ]

        let bodies = result.map {
            return try? $0.get()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    func test_void() async throws {
        let result: [Result<Void, Error>] = await [
            subject.requestVoid(address: address),
            subject.requestVoid(address: address, with: .testMake())
        ]

        XCTAssertEqual(result.count, 2)
    }

    func test_decodable() async throws {
        let result: [Result<TestInfo?, Error>] = await [
            subject.requestDecodable(TestInfo.self, address: address).map  { $0 } ,
            subject.requestDecodable(TestInfo.self, address: address, with: .testMake()).map  { $0 },
            subject.requestOptionalDecodable(TestInfo.self, address: address),
            subject.requestOptionalDecodable(TestInfo.self, address: address, with: .testMake())
        ]

        let bodies = result.map {
            return try? $0.get()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    func test_image() async throws {
        let result: [Result<Image?, Error>] = await [
            subject.requestImage(address: addressImage).map  { $0 } ,
            subject.requestImage(address: addressImage, with: .testMake()).map  { $0 },
            subject.requestOptionalImage(address: addressImage),
            subject.requestOptionalImage(address: addressImage, with: .testMake())
        ]

        for image in result {
            XCTAssertEqual(try? image.get()?.testData(), testImage.testData())
        }
    }

    func test_data() async throws {
        let result: [Result<Data?, Error>] = await [
            subject.requestData(address: address).map  { $0 } ,
            subject.requestData(address: address, with: .testMake()).map  { $0 },
            subject.requestOptionalData(address: address),
            subject.requestOptionalData(address: address, with: .testMake())
        ]

        let bodies = result.map {
            return try? $0.get()?.info()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    func test_json() async throws {
        let result: [Result<Any?, Error>] = await [
            subject.requestAny(address: address).map  { $0 } ,
            subject.requestAny(address: address, with: .testMake()).map  { $0 },
            subject.requestOptionalAny(address: address),
            subject.requestOptionalAny(address: address, with: .testMake())
        ]

        let bodies: [TestInfo?] = result.map {
            let data: Data? = try? $0.get().flatMap {
                return try? JSONSerialization.data(withJSONObject: $0)
            }
            return data?.info()
        }
        XCTAssertEqual(bodies, .init(repeating: testObj, count: result.count))
    }

    // MARK: -
    func test_recoverResponse() throws {
        let a = Result<Int?, Error>.success(2)
        let b = a.recoverResponse()
        XCTAssertEqual(try a.get(), try b.get())

        let a1 = Result<Int?, Error>.success(nil)
        let b1 = a1.recoverResponse()
        XCTAssertThrowsError(try b1.get(), RequestDecodingError.nilResponse)

        let a2 = Result<Int?, Error>.failure(RequestError.generic)
        let b2 = a2.recoverResponse()
        XCTAssertThrowsError(try b2.get(), RequestError.generic)
    }
}
