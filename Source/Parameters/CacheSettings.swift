import Foundation

public protocol RequestCache: AnyObject {
    func cachedResponse(for request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest)
    func removeCachedResponse(for request: URLRequest)
}

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
