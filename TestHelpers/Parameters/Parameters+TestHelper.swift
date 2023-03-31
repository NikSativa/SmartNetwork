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
                                isLoggingEnabled: Bool = false,
                                progressHandler: ProgressHandler? = nil,
                                userInfo: UserInfo = .init(),
                                session: Session = FakeSession(),
                                encoder: JSONEncoder = .init(),
                                decoder: JSONDecoder = .init()) -> Self {
        return .init(address: address,
                     header: header,
                     method: method,
                     body: body,
                     plugins: plugins,
                     cacheSettings: cacheSettings,
                     requestPolicy: requestPolicy,
                     timeoutInterval: timeoutInterval,
                     isLoggingEnabled: isLoggingEnabled,
                     progressHandler: progressHandler,
                     userInfo: userInfo,
                     session: session,
                     encoder: encoder,
                     decoder: decoder)
    }
}

// MARK: - Parameters.CacheSettings + SpryEquatable

extension Parameters.CacheSettings: SpryEquatable {
    public static func testMake(cache: URLCache = .init(),
                                storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly) -> Self {
        return .init(cache: cache,
                     storagePolicy: storagePolicy)
    }
}

// MARK: - Parameters.CacheSettings + Equatable

extension Parameters.CacheSettings: Equatable {
    public static func ==(lhs: Parameters.CacheSettings, rhs: Parameters.CacheSettings) -> Bool {
        return lhs.cache == rhs.cache
            && lhs.storagePolicy == rhs.storagePolicy
    }
}

// MARK: - Parameters + Equatable

extension Parameters: Equatable {
    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
        return lhs.address == rhs.address
            && lhs.header == rhs.header
            && lhs.method == rhs.method
            && lhs.body == rhs.body
            && lhs.timeoutInterval == rhs.timeoutInterval
            && lhs.cacheSettings == rhs.cacheSettings
            && lhs.requestPolicy == rhs.requestPolicy
            && lhs.plugins.hashingString == rhs.plugins.hashingString
    }
}

private extension [RequestStatePlugin] {
    var hashingString: [String] {
        let result = map { String(describing: type(of: $0)) }
        return result
    }
}
