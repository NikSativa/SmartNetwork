import Foundation
import Threading

/// A protocol that represents a ``RequestCache`` interface which can be used to mock requests in unit tests.
public protocol RequestCache: AnyObject, SmartSendable {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
    func removeCachedResponse(for request: URLRequest)
}

extension URLCache: RequestCache {}

/// A struct that manages cache settings.
public struct CacheSettings: SmartSendable {
    public let cache: RequestCache
    public let storagePolicy: URLCache.StoragePolicy

    public init(cache: RequestCache,
                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly) {
        self.cache = cache
        self.storagePolicy = storagePolicy
    }
}
