import Combine
import Foundation
import SmartNetwork
import SpryKit
import XCTest

final class TypedRequestManagerTests: XCTestCase {
    private let stubbedTimeoutInSeconds: TimeInterval = 0.1
    private let timeoutInSeconds: TimeInterval = 1
    private var observers: Set<AnyCancellable> = []
    private let url: SmartURL = .testMake(string: "http://example1.com/signin")
    private let url2: SmartURL = .testMake(string: "http://example2.com/signin")
    private let urlEmpty: SmartURL = .testMake(string: "http://exampleEmpty.com/signin")
    private let info = TestInfo(id: 1)
    private let info2 = TestInfo2(id2: 2)

    override func setUp() {
        super.setUp()

        let response = HTTPStubResponse(statusCode: .accepted, header: [:], body: .encodable(info), error: nil, delayInSeconds: stubbedTimeoutInSeconds)
        HTTPStubServer.shared.add(condition: .isAddress(url), response: response).store(in: &observers)

        let response2 = HTTPStubResponse(statusCode: .accepted, header: [:], body: .encodable(info2), error: nil, delayInSeconds: stubbedTimeoutInSeconds)
        HTTPStubServer.shared.add(condition: .isAddress(url2), response: response2).store(in: &observers)

        // `storing` is not necessary, but it is using for test coverage purpose.
        _ = HTTPStubServer.shared
            .add(condition: .isAddress(urlEmpty),
                 body: .empty,
                 delayInSeconds: stubbedTimeoutInSeconds)
            .storing(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        observers = []
    }

    // MARK: - data

    func test_api_data() {
        let result = run_test(Data.self) { subject in
            return subject.data.request(url: url)
        }
        XCTAssertEqual(result.info(), info)
    }

    func test_api_dataOptional() {
        let result = run_test(Data?.self) { subject in
            return subject.dataOptional.request(url: url)
        }
        XCTAssertEqual(result.info(), info)
    }

    private func run_test<T>(_: T.Type, _ subject: (RequestManager) -> TypedRequest<T>) -> Result<T, Error>? {
        let actual: UnsafeResult<T> = .init()
        let exp = expectation(description: #function)
        let manager = SmartRequestManager.create()

        subject(manager)
            .complete { obj in
                actual.value = obj
                exp.fulfill()
            }
            .deferredStart()
            .store(in: &observers)

        wait(for: [exp], timeout: timeoutInSeconds)
        return actual.value
    }

    // MARK: - async

    func test_api_async_data() async {
        let result = await run_async_test(Data.self) { subject in
            return await subject.data.request(url: url).async()
        }
        XCTAssertEqual(result.info(), info)
    }

    func test_api_async_dataOptional() async {
        let result = await run_async_test(Data?.self) { subject in
            return await subject.dataOptional.request(url: url).async()
        }
        XCTAssertEqual(result.info(), info)
    }

    private func run_async_test<T>(_: T.Type, _ subject: (RequestManager) async -> Result<T, Error>) async -> Result<T, Error>? {
        let manager = SmartRequestManager.create()
        let result = await subject(manager)
        return result
    }

    // MARK: - asyncWithThrowing

    func test_api_asyncWithThrowing_data() async throws {
        let result = try await run_asyncWithThrowing_test(Data.self) { subject in
            return try await subject.data.request(url: url).async().get()
        }
        XCTAssertTrue(result.info() == info)

        let result2 = try await run_asyncWithThrowing_test(Data.self) { subject in
            return try await subject.data.request(url: url2).async().get()
        }
        XCTAssertTrue(result2.info2() == info2)

        do {
            let result3 = try await run_asyncWithThrowing_test(Data?.self) { subject in
                return try await subject.data.request(url: urlEmpty).async().get()
            }
            XCTAssertNil(result3)
        } catch {
            XCTAssertEqualError(error, RequestDecodingError.nilResponse)
        }
    }

    func test_api_asyncWithThrowing_dataOptional() async throws {
        let result = try await run_asyncWithThrowing_test(Data?.self) { subject in
            return try await subject.dataOptional.request(url: url).asyncWithThrowing()
        }
        XCTAssertTrue(result?.info() == info)
    }

    private func run_asyncWithThrowing_test<T>(_: T.Type, _ subject: (RequestManager) async throws -> T) async throws -> T {
        let manager = SmartRequestManager.create()
        let result = try await subject(manager)
        return result
    }
}

private extension Result<Data, Error>? {
    func info() -> Result<TestInfo, Error> {
        switch self {
        case .none:
            return .failure(RequestError.generic)
        case let .success(data):
            return data.info().map(Result.success) ?? .failure(RequestError.generic)
        case let .failure(error):
            return .failure(error)
        }
    }
}

private extension Result<Data?, Error>? {
    func info() -> Result<TestInfo, Error> {
        switch self {
        case .none:
            return .failure(RequestError.generic)
        case let .success(data):
            return data?.info().map(Result.success) ?? .failure(RequestError.generic)
        case let .failure(error):
            return .failure(error)
        }
    }
}
