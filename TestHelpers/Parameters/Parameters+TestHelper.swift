import Foundation
import Spry

import NQueue
import NRequest

extension Parameters: SpryEquatable {
    public static func testMake(address: Address = .testMake(),
                                header: [String: String] = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: CacheSettings? = nil,
                                timeoutInterval: TimeInterval = 60,
                                queue: DelayedQueue = .async(Queue.main),
                                isLoggingEnabled: Bool = false,
                                taskKind: TaskKind = .download(progressHandler: nil)) -> Self {
        return .init(address: address,
                     header: header,
                     method: method,
                     body: body,
                     plugins: plugins,
                     cacheSettings: cacheSettings,
                     timeoutInterval: timeoutInterval,
                     queue: queue,
                     isLoggingEnabled: isLoggingEnabled,
                     taskKind: taskKind)
    }
}

extension Parameters.CacheSettings: SpryEquatable {
    public static func testMake(cache: URLCache = .init(),
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                                queue: DelayedQueue = .async(Queue.main)) -> Self {
        return .init(cache: cache,
                     storagePolicy: storagePolicy,
                     queue: queue)
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
    }
}

private extension Array where Element == Plugin {
    var descriptions: Set<String> {
        let result = map { String(describing: type(of: $0)) }
        return Set(result)
    }
}
