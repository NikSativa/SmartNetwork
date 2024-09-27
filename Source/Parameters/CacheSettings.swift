import Foundation

#if swift(>=6.0)
public protocol RequestCache: AnyObject, Sendable {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
    func removeCachedResponse(for request: URLRequest)
}
#else
public protocol RequestCache: AnyObject {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
    func removeCachedResponse(for request: URLRequest)
}
#endif

extension URLCache: RequestCache {}

public struct CacheSettings {
    public let cache: RequestCache
    public let storagePolicy: URLCache.StoragePolicy

    public init(cache: RequestCache,
                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly) {
        self.cache = cache
        self.storagePolicy = storagePolicy
    }
}

#if swift(>=6.0)
extension CacheSettings: Sendable {}
#endif
