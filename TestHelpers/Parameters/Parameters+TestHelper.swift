import Foundation
import NQueue
import NQueueTestHelpers
import NRequest
import NSpry

// MARK: - Parameters + SpryEquatable

extension Parameters: SpryEquatable {
    public static func testMake(address: Address = .testMake(),
                                header: HeaderFields = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [RequestStatePlugin] = [],
                                cacheSettings: CacheSettings? = nil,
                                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                timeoutInterval: TimeInterval = 60,
                                queue: DelayedQueue = Self.defaultResponseQueue,
                                isLoggingEnabled: Bool = false,
                                progressHandler: ProgressHandler? = nil,
                                userInfo: UserInfo = .init(),
                                session: Session = FakeSession(),
                                encoder: JSONEncoder = .init(),
                                decoder: JSONDecoder = .init(),
                                shouldAddSlashAfterEndpoint: Bool = false) -> Self {
        return .init(address: address,
                     header: header,
                     method: method,
                     body: body,
                     plugins: plugins,
                     cacheSettings: cacheSettings,
                     requestPolicy: requestPolicy,
                     timeoutInterval: timeoutInterval,
                     queue: queue,
                     isLoggingEnabled: isLoggingEnabled,
                     progressHandler: progressHandler,
                     userInfo: userInfo,
                     session: session,
                     encoder: encoder,
                     decoder: decoder,
                     shouldAddSlashAfterEndpoint: shouldAddSlashAfterEndpoint)
    }
}

// MARK: - Parameters.CacheSettings + SpryEquatable

extension Parameters.CacheSettings: SpryEquatable {
    public static func testMake(cache: URLCache = .init(),
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                                queue: DelayedQueue = Parameters.defaultResponseQueue) -> Self {
        return .init(cache: cache,
                     storagePolicy: storagePolicy,
                     queue: queue)
    }
}

// MARK: - Parameters.CacheSettings + Equatable

extension Parameters.CacheSettings: Equatable {
    public static func ==(lhs: Parameters.CacheSettings, rhs: Parameters.CacheSettings) -> Bool {
        return lhs.cache == rhs.cache
            && lhs.storagePolicy == rhs.storagePolicy
            && lhs.queue == rhs.queue
    }
}

// MARK: - Parameters + Equatable

extension Parameters: Equatable {
    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
        return lhs.address == rhs.address
            && lhs.cacheSettings == rhs.cacheSettings
            && lhs.header == rhs.header
            && lhs.isLoggingEnabled == rhs.isLoggingEnabled
            && lhs.method == rhs.method
            && lhs.body == rhs.body
            && lhs.plugins.descriptions == rhs.plugins.descriptions
            && lhs.queue == rhs.queue
            && lhs.timeoutInterval == rhs.timeoutInterval
            && lhs.userInfo == rhs.userInfo
    }
}

private extension [RequestStatePlugin] {
    var descriptions: [String] {
        let result = map { String(describing: type(of: $0)) }
        return result
    }
}
