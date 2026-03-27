#if swift(>=6.0) && canImport(SwiftSyntax600)
import Combine
import Foundation
import SpryKit
import Threading
import XCTest
@testable import SmartNetwork

final class SmartRequestTests: XCTestCase {
    let session = SmartNetworkSettings.sharedSession
    var observers: Set<AnyCancellable> = []

    let url: SmartURL = .testMake()
    let cache: FakeRequestCache = .init()
    lazy var sdkRequest = URLRequest.spry.testMake(url: try! url.url())

    lazy var cacheSettings: CacheSettings = .testMake(cache: cache)

    lazy var parameters: Parameters = .testMake(cacheSettings: cacheSettings)

    lazy var urlRequestable: FakeURLRequestRepresentation = {
        let urlRequestable: FakeURLRequestRepresentation = .init()
        urlRequestable.stub(.sdk_get).andReturn(sdkRequest)
        urlRequestable.stub(.allHTTPHeaderFields_get).andReturn(["String": "String"])
        return urlRequestable
    }()

    var subject: SmartRequest!

    lazy var setUpSubject: () -> Void = { [self] in
        subject = SmartRequest(url: .testMake(),
                               parameters: parameters,
                               userInfo: .testMake(),
                               urlRequestable: urlRequestable,
                               session: session)
    }

    override func setUp() {
        super.setUp()
        HTTPStubServer.shared
            .add(condition: .isAddress(.testMake()),
                 response: .init(statusCode: 200, body: .data("data".data(using: .utf8)!)))
            .store(in: &observers)
    }

    override func tearDown() {
        super.tearDown()
        urlRequestable.resetCallsAndStubs()
        observers = []
    }

    func test_parameters() {
        setUpSubject()
        XCTAssertEqual(subject.parameters, parameters)
        XCTAssertEqual(subject.description, "<GET request: https://www.apple.com>")
        XCTAssertEqual(subject?.debugDescription ?? "", "<GET request: https://www.apple.com>")
    }

    func test_regular_request_with_cache() async {
        setUpSubject()

        let strData: Data = "data".data(using: .utf8).unsafelyUnwrapped
        let urlResponse = HTTPURLResponse(url: sdkRequest.url.unsafelyUnwrapped,
                                          mimeType: "application/x-binary",
                                          expectedContentLength: -1,
                                          textEncodingName: nil)
        let cachedResponse = CachedURLResponse(response: urlResponse, data: strData)
        cache.stub(.cachedResponse).andReturn(cachedResponse)

        let data: SmartResponse = await subject.start()

        XCTAssertEqual(data, .testMake(request: sdkRequest, body: .data(strData), response: urlResponse))
    }

    func test_returnCacheDataDontLoad_with_cache_miss_does_not_load_network() async {
        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .returnCacheDataDontLoad)
        setUpSubject()

        cache.stub(.cachedResponse).andReturn(nil)

        let data = await subject.start()
        XCTAssertNil(data.body)
        XCTAssertNil(data.response)
        XCTAssertEqual((data.error as? URLError)?.code, .cannotLoadFromNetwork)

        XCTAssertHaveReceived(cache, .cachedResponse, countSpecifier: .exactly(1))
        XCTAssertHaveNotReceived(cache, .storeCachedResponse)
    }

    func test_description() {
        let urlRequestable: FakeURLRequestRepresentation = .init()
        var subject: SmartRequest = .init(url: .testMake(),
                                          parameters: .testMake(method: .get),
                                          userInfo: .testMake(),
                                          urlRequestable: urlRequestable,
                                          session: session)

        XCTAssertEqual(subject.description, "<GET request: https://www.apple.com>")
        XCTAssertEqual(subject.debugDescription, "<GET request: https://www.apple.com>")

        subject = SmartRequest(url: .testMake(),
                               parameters: .testMake(header: ["some": "a"], method: nil),
                               userInfo: .testMake(),
                               urlRequestable: urlRequestable,
                               session: session)

        XCTAssertEqual(subject.description, "<`No method` request: https://www.apple.com headers: [some: a]>")
        XCTAssertEqual(subject.debugDescription, "<`No method` request: https://www.apple.com headers: [some: a]>")
    }

    // MARK: - Conditional Requests (ETag / Last-Modified)

    func test_conditionalRequest_returns_cached_body_on_304() async {
        // Register a 304 stub instead of the default 200
        observers = []
        HTTPStubServer.shared
            .add(condition: .isAddress(.testMake()),
                 response: .init(statusCode: 304))
            .store(in: &observers)

        let cachedData = "cached_data".data(using: .utf8)!
        let cachedHTTPResponse = HTTPURLResponse(url: sdkRequest.url!,
                                                  statusCode: 200,
                                                  httpVersion: "HTTP/1.1",
                                                  headerFields: ["ETag": "\"abc123\""])!
        let cachedURLResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachedData)

        cache.stub(.cachedResponse).andReturn(cachedURLResponse)
        cache.stub(.removeCachedResponse).andReturn(Void())
        cache.stub(.storeCachedResponse).andReturn(Void())

        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .reloadRevalidatingCacheData)
        setUpSubject()

        let response = await subject.start()

        XCTAssertEqual(response.body, cachedData)
        XCTAssertNil(response.error)
        XCTAssertHaveReceived(cache, .storeCachedResponse)
    }

    func test_conditionalRequest_returns_fresh_body_on_200() async {
        let cachedData = "old_data".data(using: .utf8)!
        let cachedHTTPResponse = HTTPURLResponse(url: sdkRequest.url!,
                                                  statusCode: 200,
                                                  httpVersion: "HTTP/1.1",
                                                  headerFields: ["ETag": "\"abc123\""])!
        let cachedURLResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachedData)

        cache.stub(.cachedResponse).andReturn(cachedURLResponse)
        cache.stub(.removeCachedResponse).andReturn(Void())
        cache.stub(.storeCachedResponse).andReturn(Void())

        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .reloadRevalidatingCacheData)
        setUpSubject()

        let response = await subject.start()

        // Should return the fresh 200 body from stub, not the cached data
        let freshData = "data".data(using: .utf8)!
        XCTAssertEqual(response.body, freshData)
        XCTAssertNil(response.error)
    }

    func test_conditionalRequest_disabled_globally_does_not_inject_headers_on_304() async {
        let previousValue = SmartNetworkSettings.isConditionalRequestsEnabled
        SmartNetworkSettings.isConditionalRequestsEnabled = false
        defer { SmartNetworkSettings.isConditionalRequestsEnabled = previousValue }

        // Register a 304 stub
        observers = []
        HTTPStubServer.shared
            .add(condition: .isAddress(.testMake()),
                 response: .init(statusCode: 304))
            .store(in: &observers)

        let cachedData = "cached_data".data(using: .utf8)!
        let cachedHTTPResponse = HTTPURLResponse(url: sdkRequest.url!,
                                                  statusCode: 200,
                                                  httpVersion: "HTTP/1.1",
                                                  headerFields: ["ETag": "\"abc123\""])!
        let cachedURLResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachedData)

        cache.stub(.cachedResponse).andReturn(cachedURLResponse)
        cache.stub(.removeCachedResponse).andReturn(Void())
        cache.stub(.storeCachedResponse).andReturn(Void())

        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .reloadRevalidatingCacheData)
        setUpSubject()

        let response = await subject.start()

        // Without conditional requests, 304 is not intercepted — stub returns nil body
        XCTAssertNil(response.body)
    }

    func test_conditionalRequest_disabled_per_request_does_not_inject_headers_on_304() async {
        // Register a 304 stub
        observers = []
        HTTPStubServer.shared
            .add(condition: .isAddress(.testMake()),
                 response: .init(statusCode: 304))
            .store(in: &observers)

        let cachedData = "cached_data".data(using: .utf8)!
        let cachedHTTPResponse = HTTPURLResponse(url: sdkRequest.url!,
                                                  statusCode: 200,
                                                  httpVersion: "HTTP/1.1",
                                                  headerFields: ["ETag": "\"abc123\""])!
        let cachedURLResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachedData)

        cache.stub(.cachedResponse).andReturn(cachedURLResponse)
        cache.stub(.removeCachedResponse).andReturn(Void())
        cache.stub(.storeCachedResponse).andReturn(Void())

        cacheSettings = .testMake(cache: cache, useConditionalRequests: false)
        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .reloadRevalidatingCacheData)
        setUpSubject()

        let response = await subject.start()

        // Without conditional requests, 304 is not intercepted — stub returns nil body
        XCTAssertNil(response.body)
    }

    func test_conditionalRequest_no_cached_etag_does_not_inject_headers() async {
        // Cached response without ETag or Last-Modified
        let cachedData = "cached_data".data(using: .utf8)!
        let cachedHTTPResponse = HTTPURLResponse(url: sdkRequest.url!,
                                                  statusCode: 200,
                                                  httpVersion: "HTTP/1.1",
                                                  headerFields: nil)!
        let cachedURLResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachedData)

        cache.stub(.cachedResponse).andReturn(cachedURLResponse)
        cache.stub(.removeCachedResponse).andReturn(Void())
        cache.stub(.storeCachedResponse).andReturn(Void())

        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .reloadRevalidatingCacheData)
        setUpSubject()

        let response = await subject.start()

        // No conditional headers injected, so normal 200 stub response is returned
        let freshData = "data".data(using: .utf8)!
        XCTAssertEqual(response.body, freshData)
        XCTAssertNil(response.error)
    }

    func test_conditionalRequest_with_lastModified_returns_cached_body_on_304() async {
        // Register a 304 stub
        observers = []
        HTTPStubServer.shared
            .add(condition: .isAddress(.testMake()),
                 response: .init(statusCode: 304))
            .store(in: &observers)

        let cachedData = "cached_data".data(using: .utf8)!
        let cachedHTTPResponse = HTTPURLResponse(url: sdkRequest.url!,
                                                  statusCode: 200,
                                                  httpVersion: "HTTP/1.1",
                                                  headerFields: ["Last-Modified": "Wed, 21 Oct 2025 07:28:00 GMT"])!
        let cachedURLResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachedData)

        cache.stub(.cachedResponse).andReturn(cachedURLResponse)
        cache.stub(.removeCachedResponse).andReturn(Void())
        cache.stub(.storeCachedResponse).andReturn(Void())

        parameters = .testMake(cacheSettings: cacheSettings,
                               requestPolicy: .reloadRevalidatingCacheData)
        setUpSubject()

        let response = await subject.start()

        XCTAssertEqual(response.body, cachedData)
        XCTAssertNil(response.error)
    }
}
#endif
