import Foundation
import Spry

import NRequest

extension Parameters: SpryEquatable {
    static func testMake(address: Address = .testMake(),
                         header: [String: String] = [:],
                         method: HTTPMethod = .get,
                         plugins: [Plugin] = [],
                         cacheSettings: CacheSettings = .testMake(),
                         timeoutInterval: TimeInterval = 60,
                         queue: ResponseQueue = DispatchQueue.main,
                         isLoggingEnabled: Bool = false) -> Parameters {
        return Parameters(address: address,
                          header: header,
                          method: method,
                          plugins: plugins,
                          cacheSettings: cacheSettings,
                          timeoutInterval: timeoutInterval,
                          queue: queue,
                          isLoggingEnabled: isLoggingEnabled)
    }
}

extension Parameters.CacheSettings: SpryEquatable {
    static func testMake(cache: URLCache? = nil,
                         storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                         requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> Parameters.CacheSettings {
        return Parameters.CacheSettings(cache: cache,
                                        storagePolicy: storagePolicy,
                                        requestPolicy: requestPolicy)
    }
}

extension Parameters: Equatable {
    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
        return lhs.address == rhs.address
            && lhs.cacheSettings == rhs.cacheSettings
            && lhs.header == rhs.header
            && lhs.isLoggingEnabled == rhs.isLoggingEnabled
            && lhs.method == rhs.method
            && Set(lhs.plugins.map({ String(describing: type(of: $0)) })) == Set(rhs.plugins.map({ String(describing: type(of: $0)) }))
            && lhs.queue === rhs.queue
            && lhs.timeoutInterval == rhs.timeoutInterval
    }
}
