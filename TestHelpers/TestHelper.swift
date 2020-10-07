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
    public typealias FakeResponseQueue = NRequestTestHelpers.FakeResponseQueue

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
                                plugins: [Plugin] = [],
                                cacheSettings: Parameters.CacheSettings = .testMake(),
                                timeoutInterval: TimeInterval = 60,
                                queue: ResponseQueue = DispatchQueue.main,
                                isLoggingEnabled: Bool = false) -> Parameters {
        return .testMake(address: address,
                         header: header,
                         method: method,
                         plugins: plugins,
                         cacheSettings: cacheSettings,
                         timeoutInterval: timeoutInterval,
                         queue: queue,
                         isLoggingEnabled: isLoggingEnabled)
    }

    public static func testMake(cache: URLCache? = nil,
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Parameters.CacheSettings {
        return .testMake(cache: cache,
                         storagePolicy: storagePolicy,
                         requestPolicy: requestPolicy)
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
