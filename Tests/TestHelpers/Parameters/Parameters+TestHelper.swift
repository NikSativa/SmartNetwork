import Foundation
import SmartNetwork
import SpryKit

// MARK: - Parameters + SpryEquatable

extension Parameters: SpryEquatable {
    public static func testMake(header: HeaderFields = [],
                                method: HTTPMethod? = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: CacheSettings? = nil,
                                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                timeoutInterval: TimeInterval = RequestSettings.timeoutInterval,
                                progressHandler: ProgressHandler? = nil,
                                userInfo: UserInfo = .init(),
                                session: SmartURLSession? = nil) -> Self {
        return .init(header: header,
                     method: method,
                     body: body,
                     plugins: plugins,
                     cacheSettings: cacheSettings,
                     requestPolicy: requestPolicy,
                     timeoutInterval: timeoutInterval,
                     progressHandler: progressHandler,
                     userInfo: userInfo,
                     session: session)
    }

    public static func testMake(header: [String: String],
                                method: HTTPMethod? = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: CacheSettings? = nil,
                                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                timeoutInterval: TimeInterval = RequestSettings.timeoutInterval,
                                progressHandler: ProgressHandler? = nil,
                                userInfo: UserInfo = .init(),
                                session: SmartURLSession? = nil) -> Self {
        return .init(header: header,
                     method: method,
                     body: body,
                     plugins: plugins,
                     cacheSettings: cacheSettings,
                     requestPolicy: requestPolicy,
                     timeoutInterval: timeoutInterval,
                     progressHandler: progressHandler,
                     userInfo: userInfo,
                     session: session)
    }
}

// MARK: - Parameters + Equatable

extension Parameters: Equatable {
    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
        return lhs.header == rhs.header
            && lhs.method == rhs.method
            && lhs.body == rhs.body
            && lhs.timeoutInterval == rhs.timeoutInterval
            && lhs.cacheSettings == rhs.cacheSettings
            && lhs.requestPolicy == rhs.requestPolicy
            && lhs.plugins.map(\.id) == rhs.plugins.map(\.id)
    }
}
