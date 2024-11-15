import Foundation
import SpryKit
import Threading
import XCTest

@testable import SmartNetwork

final class RequestableTests: XCTestCase {
    var responses: [RequestResult] = []
    var requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

    let task: FakeSessionTask = .init()
    let session: FakeSmartURLSession = .init()
    let cache: FakeRequestCache = .init()
    let sdkRequest = URLRequest.spry.testMake(url: "apple.com")

    lazy var cacheSettings: CacheSettings = .testMake(cache: cache)

    lazy var parameters: Parameters = .testMake(cacheSettings: cacheSettings,
                                                requestPolicy: requestPolicy)

    lazy var urlRequestable: FakeURLRequestRepresentation = {
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk).andReturn(sdkRequest)
        urlRequestable.stub(.allHTTPHeaderFields).andReturn(["String": "String"])
        return urlRequestable
    }()

    var subject: Request!

    lazy var setUpSubject: () -> Void = { [self] in
        subject = Request(address: .testMake(),
                          parameters: parameters,
                          urlRequestable: urlRequestable,
                          session: session)
        subject.completion = { [weak self] data in
            self?.responses.append(data)
        }
    }

    override func tearDown() {
        super.tearDown()
        urlRequestable.resetCallsAndStubs()
        task.resetCallsAndStubs()
        session.resetCallsAndStubs()
    }

    func test_parameters() {
        setUpSubject()
        XCTAssertEqual(subject.parameters, parameters)
        XCTAssertEqual(subject.description, "<GET request: https://www.apple.com>")
        XCTAssertEqual(subject?.debugDescription ?? "", "<GET request: https://www.apple.com>")
    }

    func test_regular_request_start_cancel_start() {
        setUpSubject()

        // idle request -> nothing happen
        XCTAssertNoThrow(subject.cancel())

        XCTAssertHaveNoRecordedCalls(session)
        XCTAssertHaveNoRecordedCalls(task)

        // start
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)

        XCTAssertFalse(subject.tryStart())
        XCTAssertHaveNotReceived(task, .resume)
        XCTAssertHaveNotReceived(session, .task)

        // cancel
        task.resetCallsAndStubs()
        session.resetCallsAndStubs()

        task.stub(.isRunning).andReturn(true)
        task.stub(.cancel).andReturn()
        subject.cancel()
        XCTAssertFalse(subject.tryStart())

        XCTAssertHaveNotReceived(task, .isRunning)
        XCTAssertHaveNotReceived(task, .cancel)
        XCTAssertTrue(responses.isEmpty)
    }

    func test_regular_request_string() {
        setUpSubject()

        // create new task and retain it
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)
        cache.stub(.cachedResponse).andReturn(nil)

        // start
        XCTAssertTrue(subject.tryStart())

        XCTAssertHaveReceived(task, .resume, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(session, .task)
        XCTAssertHaveReceived(cache, .cachedResponse)

        // should stop task before triggering response
        task.stub(.cancel).andReturn()
        task.stub(.isRunning).andReturn(true)

        // receive response
        let strData: Data = "data".data(using: .utf8)!
        session.completionHandler?(strData, nil, nil)

        XCTAssertHaveReceived(task, .cancel, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(task, .isRunning, countSpecifier: .exactly(1))

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: .data(strData))
        ])
    }

    func test_regular_request_json() {
        requestPolicy = .reloadIgnoringLocalCacheData
        setUpSubject()

        // create new task and retain it
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)
        cache.stub(.removeCachedResponse).andReturn()

        // start
        XCTAssertTrue(subject.tryStart())

        XCTAssertHaveReceived(task, .resume, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(session, .task)
        XCTAssertHaveReceived(cache, .removeCachedResponse)

        // should stop task before triggering response
        task.stub(.cancel).andReturn()
        task.stub(.isRunning).andReturn(true)

        // receive response
        let jsonData: Data = "{ \"data\": 111 }".data(using: .utf8)!
        session.completionHandler?(jsonData, nil, nil)

        XCTAssertHaveReceived(task, .cancel, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(task, .isRunning, countSpecifier: .exactly(1))

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: .data(jsonData))
        ])
    }

    func test_regular_request_emptyData() {
        requestPolicy = .reloadIgnoringLocalAndRemoteCacheData
        setUpSubject()

        // create new task and retain it
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)
        cache.stub(.removeCachedResponse).andReturn()

        // start
        XCTAssertTrue(subject.tryStart())

        XCTAssertHaveReceived(task, .resume, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(session, .task)
        XCTAssertHaveReceived(cache, .removeCachedResponse)

        // should stop task before triggering response
        task.stub(.cancel).andReturn()
        task.stub(.isRunning).andReturn(true)

        // receive response
        let emptyData = Data()
        session.completionHandler?(emptyData, nil, nil)

        XCTAssertHaveReceived(task, .cancel, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(task, .isRunning, countSpecifier: .exactly(1))

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: .data(emptyData))
        ])
    }

    func test_cancel_request_before_deinit() {
        requestPolicy = .reloadIgnoringCacheData
        setUpSubject()

        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)
        cache.stub(.removeCachedResponse).andReturn()

        XCTAssertTrue(subject.tryStart())
        XCTAssertHaveReceived(task, .resume)
        XCTAssertHaveReceived(session, .task)
        XCTAssertHaveReceived(cache, .removeCachedResponse)

        // deinit request before request ended
        task.resetCallsAndStubs()
        task.stub(.isRunning).andReturn(true)
        task.stub(.cancel).andReturn()
        subject = nil

        XCTAssertHaveReceived(task, .isRunning)
        XCTAssertHaveReceived(task, .cancel)
    }

    func test_cancel_request_before_response() {
        requestPolicy = .reloadRevalidatingCacheData
        setUpSubject()

        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)
        cache.stub(.removeCachedResponse).andReturn()

        XCTAssertTrue(subject.tryStart())
        XCTAssertHaveReceived(task, .resume)
        XCTAssertHaveReceived(session, .task)
        XCTAssertHaveReceived(cache, .removeCachedResponse)

        // cancel request before request ended
        task.resetCallsAndStubs()
        task.stub(.isRunning).andReturn(true)
        task.stub(.cancel).andReturn()

        subject.cancel()

        XCTAssertHaveReceived(task, .isRunning)
        XCTAssertHaveReceived(task, .cancel)

        // receive response
        session.completionHandler?(nil, nil, nil)

        XCTAssertEqual(responses, [])
    }

    func test_regular_request_without_cache() {
        requestPolicy = .useProtocolCachePolicy
        setUpSubject()

        session.stub(.task).andReturn(task)
        task.stub(.progress).andReturn(Progress())
        task.stub(.resume).andReturn()
        task.stub(.isRunning).andReturn(false)
        cache.stub(.cachedResponse).andReturn(nil)

        XCTAssertTrue(subject.tryStart())
        XCTAssertHaveReceived(cache, .cachedResponse)

        let strData: Data = "data".data(using: .utf8).unsafelyUnwrapped
        let urlResponse = HTTPURLResponse(url: sdkRequest.url.unsafelyUnwrapped,
                                          mimeType: "application/x-binary",
                                          expectedContentLength: -1,
                                          textEncodingName: nil)
        cache.stub(.storeCachedResponse).andReturn()

        session.completionHandler?(strData, urlResponse, nil)
        XCTAssertHaveReceived(cache, .storeCachedResponse)

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: .data(strData), response: urlResponse)
        ])
    }

    func test_regular_request_with_cache() {
        requestPolicy = .useProtocolCachePolicy
        setUpSubject()

        session.stub(.task).andReturn(task)
        task.stub(.progress).andReturn(Progress())
        task.stub(.resume).andReturn()
        task.stub(.isRunning).andReturn(false)

        let strData: Data = "data".data(using: .utf8).unsafelyUnwrapped
        let urlResponse = HTTPURLResponse(url: sdkRequest.url.unsafelyUnwrapped,
                                          mimeType: "application/x-binary",
                                          expectedContentLength: -1,
                                          textEncodingName: nil)
        let cachedResponse = CachedURLResponse(response: urlResponse, data: strData)
        cache.stub(.cachedResponse).andReturn(cachedResponse)

        XCTAssertTrue(subject.tryStart())

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: .data(strData), response: urlResponse)
        ])
    }

    func test_description() {
        let urlRequestable: FakeURLRequestRepresentation = .init()
        var subject: Request! = Request(address: .testMake(),
                                        parameters: .testMake(method: .get),
                                        urlRequestable: urlRequestable,
                                        session: session)

        XCTAssertEqual(subject.description, "<GET request: https://www.apple.com>")
        XCTAssertEqual(subject.debugDescription, "Optional(<GET request: https://www.apple.com>)")

        subject = Request(address: .testMake(),
                          parameters: .testMake(header: ["some": "a"], method: nil),
                          urlRequestable: urlRequestable,
                          session: session)

        XCTAssertEqual(subject!.description, "<`No method` request: https://www.apple.com headers: [some: a]>")
        XCTAssertEqual(subject!.debugDescription, "<`No method` request: https://www.apple.com headers: [some: a]>")
    }
}
