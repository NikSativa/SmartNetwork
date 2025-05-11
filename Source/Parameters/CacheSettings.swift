import Foundation
import Threading

/// A protocol abstraction for caching `URLRequest` responses.
///
/// Conforming types provide access to a response cache, allowing for storage, retrieval, and removal of
/// cached `URLRequest` responses. This protocol enables mocking or substituting the cache implementation,
/// particularly in unit tests.
public protocol RequestCache: AnyObject, SmartSendable {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
    func removeCachedResponse(for request: URLRequest)
}

extension URLCache: RequestCache {}

/// Encapsulates cache configuration for network requests.
///
/// `CacheSettings` specifies which cache to use and what storage policy to apply when storing cached responses.
public struct CacheSettings: SmartSendable {
    public let cache: RequestCache
    public let storagePolicy: URLCache.StoragePolicy

    /// Creates a new `CacheSettings` instance with a specified cache and storage policy.
    ///
    /// - Parameters:
    ///   - cache: An object conforming to `RequestCache` used to store and retrieve responses.
    ///   - storagePolicy: The policy that determines how the cached response is stored (default is `.allowedInMemoryOnly`).
    public init(cache: RequestCache,
                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly) {
        self.cache = cache
        self.storagePolicy = storagePolicy
    }
}
