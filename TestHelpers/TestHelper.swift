import Foundation
import Spry

import NRequest

/// make NRequest hidden from main app, but all helpers can be visible via `public typealias Helpers = NRequestTestHelpers.Helpers`
public enum Helpers {
    public typealias FakePlugin = NRequestTestHelpers.FakePlugin
    public typealias FakeAuthTokenProvider = NRequestTestHelpers.FakeAuthTokenProvider
    public typealias FakePluginProvider = NRequestTestHelpers.FakePluginProvider
    public typealias FakeStorage = NRequestTestHelpers.FakeStorage
    public typealias FakeKeyedStorage = NRequestTestHelpers.FakeKeyedStorage
    public typealias FakeRequestFactory<Error: AnyError> = NRequestTestHelpers.FakeRequestFactory<Error>
    public typealias FakeResponseQueue = NRequestTestHelpers.FakeDispatchResponseQueue
    public typealias FakeRefreshToken = NRequestTestHelpers.FakeRefreshToken

    public static func testMake(host: String = "",
                                endpoint: String? = nil,
                                queryItems: [String: String] = [:]) -> Address {
        return .testMake(host: host,
                         endpoint: endpoint,
                         queryItems: queryItems)
    }

    public static func testMake(address: Address = .testMake(),
                                header: [String: String] = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: Parameters.CacheSettings = .testMake(),
                                timeoutInterval: TimeInterval = 60,
                                queue: ResponseQueue = .async(DispatchQueue.main),
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
                                queue: ResponseQueue = .async(DispatchQueue.main)) -> Parameters.CacheSettings {
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
}
