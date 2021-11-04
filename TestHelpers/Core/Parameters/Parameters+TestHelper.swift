import Foundation
import NSpry

import NQueue
import NQueueTestHelpers
import NRequest

extension Parameters: SpryEquatable {
    public static func testMake(address: Address = .testMake(),
                                header: HeaderFields = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: CacheSettings? = nil,
                                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                timeoutInterval: TimeInterval = 60,
                                queue: DelayedQueue = Self.defaultResponseQueue,
                                isLoggingEnabled: Bool = false,
                                taskKind: TaskKind? = nil,
                                userInfo: UserInfo = .init(),
                                session: Session = FakeSession()) -> Self {
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
                     taskKind: taskKind,
                     userInfo: userInfo,
                     session: session)
    }
}

extension Parameters.CacheSettings: SpryEquatable {
    public static func testMake(cache: URLCache = .init(),
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                                queue: DelayedQueue = Parameters.defaultResponseQueue) -> Self {
        return .init(cache: cache,
                     storagePolicy: storagePolicy,
                     queue: queue)
    }
}

extension Parameters.CacheSettings: Equatable {
    public static func ==(lhs: Parameters.CacheSettings, rhs: Parameters.CacheSettings) -> Bool {
        return lhs.cache == rhs.cache
            && lhs.storagePolicy == rhs.storagePolicy
            && lhs.queue == rhs.queue
    }
}

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

public extension Parameters.UserInfo {
    static func ==(lhs: Parameters.UserInfo, _: Parameters.UserInfo) -> Bool {
        let a = try? JSONSerialization.data(withJSONObject: lhs, options: [])
        let b = try? JSONSerialization.data(withJSONObject: lhs, options: [])
        return a != nil && a == b
    }
}

private extension Array where Element == Plugin {
    var descriptions: Set<String> {
        let result = map { String(describing: type(of: $0)) }
        return Set(result)
    }
}
