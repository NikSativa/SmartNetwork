import Foundation

/// Namespace for plugins. You can create your own plugins and add them to this namespace.
public enum Plugins {}

#if swift(>=6.0)
/// Protocol that defines the mechanism of request interception and response validation.
public protocol Plugin: Sendable {
    /// A unique ID that guarantees that plugins are not duplicated
    ///
    /// - Note: you can use helpers **makeHash()** or **makeHash(withAdditionalHash:...)** to generate a unique ID
    var id: AnyHashable { get }

    /// The priority in which the plugin will be executed in the list of plugins.
    var priority: PluginPriority { get }

    /// A function that will be called before the request is sent.
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestRepresentation)

    /// A function that will be called after the response is received.
    ///
    /// - Note: if the response is not successful, you can throw an error here.
    /// - Important: only the first error thrown will be passed to the completion block and the rest will be ignored.
    func verify(data: RequestResult,
                userInfo: UserInfo) throws

    /// Just before the completion call
    func didFinish(withData data: RequestResult, userInfo: UserInfo)

    /// Super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine')
    func willSend(_ parameters: Parameters,
                  request: URLRequestRepresentation,
                  userInfo: UserInfo)

    /// Super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine')
    func didReceive(_ parameters: Parameters,
                    request: URLRequestRepresentation,
                    data: RequestResult,
                    userInfo: UserInfo)

    /// Just a notification that the request was somehow cancelled. can be called at any time and multiple times. for debug purposes or your own logic
    ///
    /// - Note: has an empty default implementation
    func wasCancelled(_ parameters: Parameters,
                      request: URLRequestRepresentation,
                      userInfo: UserInfo)
}
#else
/// Protocol that defines the mechanism of request interception and response validation.
public protocol Plugin {
    /// A unique ID that guarantees that plugins are not duplicated
    ///
    /// - Note: you can use helpers **makeHash()** or **makeHash(withAdditionalHash:...)** to generate a unique ID
    var id: AnyHashable { get }

    /// The priority in which the plugin will be executed in the list of plugins.
    var priority: PluginPriority { get }

    /// A function that will be called before the request is sent
    func prepare(_ parameters: Parameters,
                 request: inout URLRequestRepresentation)

    /// A function that will be called after the response is received
    ///
    /// - Note: if the response is not successful, you can throw an error here.
    /// - Important: only the first error thrown will be passed to the completion block and the rest will be ignored.
    func verify(data: RequestResult,
                userInfo: UserInfo) throws

    /// Just before the completion call
    func didFinish(withData data: RequestResult, userInfo: UserInfo)

    /// Super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine')
    func willSend(_ parameters: Parameters,
                  request: URLRequestRepresentation,
                  userInfo: UserInfo)

    /// Super internal level which can be called multiple time based on your Manager's config ('maxAttemptNumber' or/and 'stopTheLine')
    func didReceive(_ parameters: Parameters,
                    request: URLRequestRepresentation,
                    data: RequestResult,
                    userInfo: UserInfo)

    /// Just a notification that the request was somehow cancelled. can be called at any time and multiple times. for debug purposes or your own logic
    ///
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

    /// Creates a unique ID for the plugin
    static func makeHash() -> AnyHashable {
        return makeHashStr()
    }

    /// Creates a unique ID for the plugin with additional hash value.
    static func makeHash(withAdditionalHash hash: some Hashable) -> AnyHashable {
        if let hash = hash as? String {
            return [makeHashStr(), hash].joined(separator: ".")
        }
        return [makeHash(), hash]
    }

    func wasCancelled(_ parameters: Parameters,
                      request: URLRequestRepresentation,
                      userInfo: UserInfo) {
        // nothing to do
    }

    private static func makeHashStr() -> String {
        return String(reflecting: self)
    }
}

internal extension [Plugin] {
    func unified() -> [Plugin] {
        var unique: [Plugin] = []
        var s: Set<AnyHashable> = []
        for element in self {
            if s.insert(element.id).inserted {
                unique.append(element)
            }
        }

        return unique
    }
}
