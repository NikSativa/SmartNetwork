import Foundation
import SmartNetwork
import SpryKit
import Threading

// MARK: - CacheSettings + SpryEquatable

extension CacheSettings: SpryEquatable {
    public static func testMake(cache: RequestCache? = nil,
                                responseQueue: DelayedQueue = .absent,
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly) -> Self {
        let cache = cache ?? URLCache(memoryCapacity: 1024 * 30, diskCapacity: 1024 * 30)
        return .init(cache: cache,
                     responseQueue: responseQueue,
                     storagePolicy: storagePolicy)
    }
}

// MARK: - CacheSettings + Equatable

extension CacheSettings: Equatable {
    public static func ==(lhs: CacheSettings, rhs: CacheSettings) -> Bool {
        return lhs.cache === rhs.cache
            && lhs.storagePolicy == rhs.storagePolicy
    }
}

public extension URLCache {
    static func testMake(memoryCapacity: Int = 1024 * 30,
                         diskCapacity: Int = 1024 * 30,
                         directory: URL? = nil) -> URLCache {
        return .init(memoryCapacity: memoryCapacity,
                     diskCapacity: diskCapacity,
                     directory: directory)
    }
}
