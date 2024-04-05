import Foundation
import NQueue
import NSpry
import XCTest

@testable import NRequest
@testable import NRequestTestHelpers

final class RequestableTests: XCTestCase {
    func test_regular_request() {
        var responses: [RequestResult] = []
        let task: FakeSessionTask = .init()
        let session: FakeSession = .init()
        let parameters: Parameters = .testMake(session: session)

        let sdkRequest = URLRequest.spry.testMake(url: "google.com")
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk).andReturn(sdkRequest)
        urlRequestable.stub(.allHTTPHeaderFields).andReturn(["String": "String"])

        let subject = Request.create(address: .testMake(),
                                     with: parameters,
                                     urlRequestable: urlRequestable)
        subject.completion = { data in
            responses.append(data)
        }
        XCTAssertEqual(subject.parameters, parameters)
        XCTAssertEqual((subject as! Request).description, "<GET request: https://google.com>")
        XCTAssertEqual((subject as! Request).debugDescription, "<GET request: https://google.com>")

        // idle request -> nothing happen
        XCTAssertNoThrow(subject.cancel())

        XCTAssertHaveNoRecordedCalls(session)
        XCTAssertHaveNoRecordedCalls(task)

        // start
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)

        subject.start()
        XCTAssertHaveReceived(task, .resume)
        XCTAssertHaveReceived(session, .task)

        // cancel
        task.resetCallsAndStubs()
        session.resetCallsAndStubs()

        task.stub(.isRunning).andReturn(true)
        task.stub(.cancel).andReturn()
        subject.cancel()

        XCTAssertHaveReceived(task, .isRunning)
        XCTAssertHaveReceived(task, .cancel)
        XCTAssertTrue(responses.isEmpty)

        // reset everything before start again
        task.resetCallsAndStubs()
        session.resetCallsAndStubs()

        // create new task and retain it
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)

        // start again
        subject.start()

        XCTAssertHaveReceived(task, .resume, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(session, .task)

        // should stop task before triggering response
        task.stub(.cancel).andReturn()
        task.stub(.isRunning).andReturn(true)

        // receive response
        session.completionHandler?(nil, nil, nil)

        XCTAssertEqual(responses, [.testMake(request: sdkRequest)])
        XCTAssertHaveReceived(task, .cancel, countSpecifier: .exactly(1))
        XCTAssertHaveReceived(task, .isRunning, countSpecifier: .exactly(1))

        // impossible behavior, but expected that response can be received more then once
        // test logger
        let strData = "data".data(using: .utf8)
        session.completionHandler?(strData, nil, nil)
        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest),
            .testMake(request: sdkRequest, body: strData)
        ])

        let jsonData = "{ \"data\": 111 }".data(using: .utf8)
        session.completionHandler?(jsonData, nil, nil)
        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest),
            .testMake(request: sdkRequest, body: strData),
            .testMake(request: sdkRequest, body: jsonData)
        ])

        let emptyData = Data()
        session.completionHandler?(emptyData, nil, nil)
        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest),
            .testMake(request: sdkRequest, body: strData),
            .testMake(request: sdkRequest, body: jsonData),
            .testMake(request: sdkRequest, body: emptyData)
        ])
    }

    func test_cancel_request_before_deinit() {
        var responses: [RequestResult] = []
        let task: FakeSessionTask = .init()
        let session: FakeSession = .init()
        let parameters: Parameters = .testMake(session: session)

        let sdkRequest = URLRequest.spry.testMake(url: "google.com")
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk).andReturn(sdkRequest)
        urlRequestable.stub(.allHTTPHeaderFields).andReturn(["String": "String"])

        var subject: Requestable! = Request.create(address: .testMake(),
                                                   with: parameters,
                                                   urlRequestable: urlRequestable)
        subject.completion = { data in
            responses.append(data)
        }

        XCTAssertEqual(subject.parameters, parameters)
        XCTAssertEqual((subject as! Request).description, "<GET request: https://google.com>")
        XCTAssertEqual((subject as! Request).debugDescription, "<GET request: https://google.com>")

        // idle request -> nothing happen
        XCTAssertNoThrow(subject.cancel())

        XCTAssertHaveNoRecordedCalls(session)
        XCTAssertHaveNoRecordedCalls(task)

        // start
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)

        subject.start()
        XCTAssertHaveReceived(task, .resume)
        XCTAssertHaveReceived(session, .task)

        // deinit request before request ended
        task.resetCallsAndStubs()
        task.stub(.isRunning).andReturn(true)
        task.stub(.cancel).andReturn()
        subject = nil

        XCTAssertHaveReceived(task, .isRunning)
        XCTAssertHaveReceived(task, .cancel)
    }

    func test_cancel_request_before_response() {
        var responses: [RequestResult] = []
        let task: FakeSessionTask = .init()
        let session: FakeSession = .init()

        let cache: FakeRequestCache = .init()
        let cacheSettings: CacheSettings = .testMake(cache: cache)

        let parameters: Parameters = .testMake(cacheSettings: cacheSettings,
                                               requestPolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                               session: session)

        let sdkRequest = URLRequest.spry.testMake(url: "google.com")
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk).andReturn(sdkRequest)
        urlRequestable.stub(.allHTTPHeaderFields).andReturn(["String": "String"])

        let subject = Request.create(address: .testMake(),
                                     with: parameters,
                                     urlRequestable: urlRequestable)
        subject.completion = { data in
            responses.append(data)
        }

        XCTAssertEqual(subject.parameters, parameters)
        XCTAssertEqual((subject as! Request).description, "<GET request: https://google.com>")
        XCTAssertEqual((subject as! Request).debugDescription, "<GET request: https://google.com>")

        // idle request -> nothing happen
        XCTAssertNoThrow(subject.cancel())

        XCTAssertHaveNoRecordedCalls(session)
        XCTAssertHaveNoRecordedCalls(task)

        // start
        task.stub(.resume).andReturn()
        session.stub(.task).andReturn(task)
        cache.stub(.removeCachedResponse).andReturn()

        subject.start()
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

    func test_regular_request_with_cache() {
        var responses: [RequestResult] = []
        let task: FakeSessionTask = .init()
        let session: FakeSession = .init()

        let cache: FakeRequestCache = .init()
        let cacheSettings: CacheSettings = .testMake(cache: cache)

        let parameters: Parameters = .testMake(cacheSettings: cacheSettings,
                                               requestPolicy: .returnCacheDataElseLoad,
                                               progressHandler: { _ in },
                                               session: session)

        let sdkRequest = URLRequest.spry.testMake(url: "google.com")
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk).andReturn(sdkRequest)
        urlRequestable.stub(.allHTTPHeaderFields).andReturn(["String": "String"])

        let subject = Request.create(address: .testMake(host: "http://google.com"),
                                     with: parameters,
                                     urlRequestable: urlRequestable)
        subject.completion = { data in
            responses.append(data)
        }

        XCTAssertEqual(subject.parameters, parameters)
        XCTAssertEqual((subject as! Request).description, "<GET request: broken url>")
        XCTAssertEqual((subject as! Request).debugDescription, "<GET request: broken url>")

        // idle request -> nothing happen
        XCTAssertNoThrow(subject.cancel())

        XCTAssertHaveNoRecordedCalls(session)
        XCTAssertHaveNoRecordedCalls(task)

        // start
        session.stub(.task).andReturn(task)
        task.stub(.progress).andReturn(Progress())
        task.stub(.resume).andReturn()
        task.stub(.isRunning).andReturn(false)
        cache.stub(.cachedResponse).andReturn(nil)

        subject.start()
        XCTAssertHaveReceived(cache, .cachedResponse)

        let strData = "data".data(using: .utf8).unsafelyUnwrapped
        let urlResponse = HTTPURLResponse(url: sdkRequest.url.unsafelyUnwrapped,
                                          mimeType: "application/x-binary",
                                          expectedContentLength: -1,
                                          textEncodingName: nil)
        cache.stub(.storeCachedResponse).andReturn()

        session.completionHandler?(strData, urlResponse, nil)
        XCTAssertHaveReceived(cache, .storeCachedResponse)

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: strData, response: urlResponse)
        ])

        let cachedResponse = CachedURLResponse(response: urlResponse, data: strData)
        cache.stubAgain(.cachedResponse).andReturn(cachedResponse)
        subject.start()

        XCTAssertEqual(responses, [
            .testMake(request: sdkRequest, body: strData, response: urlResponse),
            .testMake(request: sdkRequest, body: strData, response: urlResponse)
        ])
    }
}
