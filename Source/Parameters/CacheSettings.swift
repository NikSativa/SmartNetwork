import Foundation
import Threading

/// A protocol abstraction for caching `URLRequest` responses.
///
/// Conforming types provide access to a response cache, allowing for storage, retrieval, and removal of
/// cached `URLRequest` responses. This protocol enables mocking or substituting the cache implementation,
/// particularly in unit tests.
public protocol RequestCache: AnyObject, SmartSendable {
    /// Returns cached response for request when available.
    ///
    /// - Parameter request: Lookup key request.
    /// - Returns: Cached response or `nil`.
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    /// Stores cached response for request.
    ///
    /// - Parameters:
    ///   - cachedResponse: Response payload to store.
    ///   - request: Request key.
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
    /// Removes cached response for request key.
    ///
    /// - Parameter request: Request key to clear.
    func removeCachedResponse(for request: URLRequest)
}

extension URLCache: RequestCache {}

/// Encapsulates cache configuration for network requests.
///
/// `CacheSettings` specifies which cache to use and what storage policy to apply when storing cached responses.
public struct CacheSettings: SmartSendable {
    /// Backing cache implementation used to store/retrieve responses.
    public let cache: RequestCache
    /// Storage policy applied when saving responses.
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
