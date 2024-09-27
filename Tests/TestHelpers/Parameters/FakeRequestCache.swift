import Foundation
import SpryKit
import Threading

@testable import SmartNetwork

public final class FakeRequestCache: RequestCache, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case cachedResponse = "cachedResponse(for:)"
        case storeCachedResponse = "storeCachedResponse(_:for:)"
        case removeCachedResponse = "removeCachedResponse(for:)"
    }

    public init() {}

    public func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        return spryify(arguments: request)
    }

    public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        return spryify(arguments: cachedResponse, request)
    }

    public func removeCachedResponse(for request: URLRequest) {
        return spryify(arguments: request)
    }
}
