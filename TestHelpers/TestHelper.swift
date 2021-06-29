import Foundation
import NSpry

import NQueue
import NRequest

/// make NRequest hidden from main app, but all helpers can be visible via `public typealias Helpers = NRequestTestHelpers.Helpers`
public enum Helpers {
    public typealias FakePlugin = NRequestTestHelpers.FakePlugin
    public typealias FakeBearerTokenProvider = NRequestTestHelpers.FakeBearerTokenProvider
    public typealias FakePluginProvider = NRequestTestHelpers.FakePluginProvider
    public typealias FakeRequestFactory<Error: AnyError> = NRequestTestHelpers.FakeRequestFactory<Error>
    public typealias FakeRefreshToken = NRequestTestHelpers.FakeRefreshToken
    public typealias FakeURLRequestable = NRequestTestHelpers.FakeURLRequestable

    public static func testMake(scheme: Address.Scheme? = .https,
                                host: String = "",
                                path: [String] = [],
                                queryItems: [String: String] = [:]) -> Address {
        return .address(scheme: scheme,
                        host: host,
                        path: path,
                        queryItems: queryItems)
    }

    public static func testMake(scheme: URLRepresentation.Scheme? = .https,
                                host: String = "",
                                path: [String] = [],
                                queryItems: [String: String] = [:]) -> URLRepresentation {
        return .init(scheme: scheme,
                     host: host,
                     path: path,
                     queryItems: queryItems)
    }

    public static func testMake(address: Address = .testMake(),
                                header: [String: String] = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: Parameters.CacheSettings = .testMake(),
                                timeoutInterval: TimeInterval = 60,
                                queue: DelayedQueue = .async(Queue.main),
                                isLoggingEnabled: Bool = false,
                                taskKind: Parameters.TaskKind = .download(progressHandler: nil)) -> Parameters {
        return Parameters(address: address,
                          header: header,
                          method: method,
                          body: body,
                          plugins: plugins,
                          cacheSettings: cacheSettings,
                          timeoutInterval: timeoutInterval,
                          queue: queue,
                          isLoggingEnabled: isLoggingEnabled,
                          taskKind: taskKind)
    }

    public static func testMake(cache: URLCache = .init(),
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                                queue: DelayedQueue = .async(Queue.main)) -> Parameters.CacheSettings {
        return Parameters.CacheSettings(cache: cache,
                                        storagePolicy: storagePolicy,
                                        queue: queue)
    }

    public static func testMake(_ string: String = "http://www.some.com") -> URL {
        return .testMake(string)
    }

    public static func testMake(url: URL = .testMake(),
                                headers: [String: String] = [:]) -> URLRequest {
        return .testMake(url: url,
                         headers: headers)
    }

    public static func testMake(url: String,
                                headers: [String: String] = [:]) -> URLRequest {
        return .testMake(url: URL.testMake(url),
                         headers: headers)
    }
}
