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
}
#endif
