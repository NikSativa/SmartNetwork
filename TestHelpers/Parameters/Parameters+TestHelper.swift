import Foundation
import Spry

import NRequest

extension Parameters: SpryEquatable {
    public static func testMake(address: Address = .testMake(),
                                header: [String: String] = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: CacheSettings = .testMake(),
                                timeoutInterval: TimeInterval = 60,
                                queue: ResponseQueue = DispatchQueue.main,
                                isLoggingEnabled: Bool = false,
                                taskKind: TaskKind = .download(progressHandler: nil)) -> Parameters {
        return Parameters(address: address,
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
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly) -> Parameters.CacheSettings {
        return Parameters.CacheSettings(cache: cache,
                                        storagePolicy: storagePolicy)
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
            && Set(lhs.plugins.map({ String(describing: type(of: $0)) })) == Set(rhs.plugins.map({ String(describing: type(of: $0)) }))
            && lhs.queue === rhs.queue
            && lhs.timeoutInterval == rhs.timeoutInterval
    }
}
