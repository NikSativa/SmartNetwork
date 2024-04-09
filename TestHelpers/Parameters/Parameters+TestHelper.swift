import SmartNetwork
import Foundation
import SpryKit

// MARK: - Parameters + SpryEquatable

extension Parameters: SpryEquatable {
    public static func testMake(header: HeaderFields = [:],
                                method: HTTPMethod = .get,
                                body: Body = .empty,
                                plugins: [Plugin] = [],
                                cacheSettings: CacheSettings? = nil,
                                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                timeoutInterval: TimeInterval = 60,
                                progressHandler: ProgressHandler? = nil,
                                userInfo: UserInfo = .init(),
                                session: Session = FakeSession(),
                                encoder: JSONEncoder = .init(),
                                decoder: JSONDecoder = .init()) -> Self {
        return .init(header: header,
                     method: method,
                     body: body,
                     plugins: plugins,
                     cacheSettings: cacheSettings,
                     requestPolicy: requestPolicy,
                     timeoutInterval: timeoutInterval,
                     progressHandler: progressHandler,
                     userInfo: userInfo,
                     session: session,
                     encoder: encoder,
                     decoder: decoder)
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
            && lhs.plugins.hashingString == rhs.plugins.hashingString
    }
}

private extension [Plugin] {
    var hashingString: [String] {
        let result = map {
            return String(describing: type(of: $0))
        }
        return result
    }
}
