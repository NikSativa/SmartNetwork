import Foundation

/// namespace
public enum Plugins {}

#if swift(>=6.0)
public protocol Plugin: Sendable {
    /// a unique ID that guarantees that plugins are not duplicated
    ///
    /// - use helpers **makeHash()** or **makeHash(withAdditionalHash:...)**
    var id: AnyHashable { get }

    func prepare(_ parameters: Parameters,
                 request: inout URLRequestRepresentation)

    func verify(data: RequestResult,
                userInfo: UserInfo) throws

    /// just before the completion call
    func didFinish(withData data: RequestResult, userInfo: UserInfo)

    /// super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine'
    func willSend(_ parameters: Parameters,
                  request: URLRequestRepresentation,
                  userInfo: UserInfo)

    /// super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine'
    func didReceive(_ parameters: Parameters,
                    request: URLRequestRepresentation,
                    data: RequestResult,
                    userInfo: UserInfo)

    /// just a notification that the request was somehow cancelled. can be called at any time and multiple times. for debug purposes or your own logic
    /// - Note: has an empty default implementation
    func wasCancelled(_ parameters: Parameters,
                      request: URLRequestRepresentation,
                      userInfo: UserInfo)
}
#else
public protocol Plugin {
    /// a unique ID that guarantees that plugins are not duplicated
    ///
    /// - use helpers **makeHash()** or **makeHash(withAdditionalHash:...)**
    var id: AnyHashable { get }

    func prepare(_ parameters: Parameters,
                 request: inout URLRequestRepresentation)

    func verify(data: RequestResult,
                userInfo: UserInfo) throws

    /// just before the completion call
    func didFinish(withData data: RequestResult, userInfo: UserInfo)

    /// super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine'
    func willSend(_ parameters: Parameters,
                  request: URLRequestRepresentation,
                  userInfo: UserInfo)

    /// super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine'
    func didReceive(_ parameters: Parameters,
                    request: URLRequestRepresentation,
                    data: RequestResult,
                    userInfo: UserInfo)

    /// just a notification that the request was somehow cancelled. can be called at any time and multiple times. for debug purposes or your own logic
    /// - Note: has an empty default implementation
    func wasCancelled(_ parameters: Parameters,
                      request: URLRequestRepresentation,
                      userInfo: UserInfo)
}
#endif

public extension Plugin {
    var id: AnyHashable {
        return Self.makeHash()
    }

    static func makeHash() -> AnyHashable {
        return String(reflecting: self)
    }

    static func makeHash(withAdditionalHash hash: some Hashable) -> AnyHashable {
        let components: [AnyHashable] = [makeHash(), hash]
        return components
    }

    func wasCancelled(_ parameters: Parameters,
                      request: URLRequestRepresentation,
                      userInfo: UserInfo) {
        // nothing to do
    }
}

internal extension [Plugin] {
    func unified() -> [Element] {
        var unique: [Element] = []
        var s: Set<AnyHashable> = []
        for element in self {
            if s.insert(element.id).inserted {
                unique.append(element)
            }
        }

        return unique
    }
}
