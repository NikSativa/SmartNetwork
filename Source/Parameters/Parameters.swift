import Foundation
import Threading

/// This struct represents the parameters required for a network request.
///
/// - Note: You can use ``UserInfo`` to pass data between any part of the network layer like ``Plugin``, ``Stopper`` etc.
public struct Parameters {
    /// The header fields for the request.
    public let header: HeaderFields

    /// The HTTP method for the request.
    public let method: HTTPMethod?

    /// The body of the request.
    public let body: Body?

    /// The timeout interval for the request. Default is 30 seconds. Change it using `RequestSettings.timeoutInterval`.
    public let timeoutInterval: TimeInterval

    /// The cache settings for the request.
    public let cacheSettings: CacheSettings?

    /// The cache policy for the request. Default is `.useProtocolCachePolicy`.
    public let requestPolicy: URLRequest.CachePolicy

    /// The plugins for the request.
    public internal(set) var plugins: [Plugin]

    /// A flag to ignore the `StopTheLine` for the request.
    ///
    /// - Important: This flag is useful for requests that should not be stopped by the `StopTheLine` mechanism.
    public let shouldIgnoreStopTheLine: Bool

    /// The progress handler for the request
    public let progressHandler: ProgressHandler?

    /// The session for the request
    public let session: SmartURLSession?

    /// ``UserInfo`` for the request.
    ///
    /// - Note: You can use ``UserInfo`` to pass data between any part of the network layer like ``Plugin``, ``Stopper`` etc.
    public let userInfo: UserInfo

    /// Initializes a new Parameters object.
    public init(header: HeaderFields = [:],
                method: HTTPMethod? = .get,
                body: Body? = nil,
                plugins: [Plugin] = [],
                cacheSettings: CacheSettings? = nil,
                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                timeoutInterval: TimeInterval = RequestSettings.timeoutInterval,
                progressHandler: ProgressHandler? = nil,
                userInfo: UserInfo = .init(),
                shouldIgnoreStopTheLine: Bool = false,
                session: SmartURLSession? = nil) {
        self.header = header
        self.method = method
        self.body = body
        self.plugins = plugins
        self.timeoutInterval = timeoutInterval
        self.cacheSettings = cacheSettings
        self.requestPolicy = requestPolicy
        self.progressHandler = progressHandler
        self.userInfo = userInfo
        self.shouldIgnoreStopTheLine = shouldIgnoreStopTheLine
        self.session = session
    }
}

public extension Parameters {
    /// Generates a URLRequest representation of the Parameters for a given address.
    /// - Parameters:
    ///   - address: The ``Address`` to generate the ``URL`` for the request.
    /// - Returns: A representation of the ``URLRequest`` based on the Parameters.
    /// - Throws: An error if ``URL`` creation or request building fails.
    func urlRequest(for address: Address) throws -> URLRequestRepresentation {
        let url = try address.url()
        var request = URLRequest(url: url,
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method?.toString()

        for item in header {
            request.addValue(item.value, forHTTPHeaderField: item.key)
        }

        try body.fill(&request)

        return request
    }

    /// Adds headers to the parameters.
    @inline(__always)
    static func +(lhs: Self, rhs: HeaderFields) -> Self {
        return .init(header: lhs.header + rhs,
                     method: lhs.method,
                     body: lhs.body,
                     plugins: lhs.plugins,
                     cacheSettings: lhs.cacheSettings,
                     requestPolicy: lhs.requestPolicy,
                     timeoutInterval: lhs.timeoutInterval,
                     progressHandler: lhs.progressHandler,
                     userInfo: lhs.userInfo,
                     session: lhs.session)
    }

    /// Adds plugins to the parameters.
    @inline(__always)
    static func +(lhs: Self, rhs: [Plugin]) -> Self {
        return .init(header: lhs.header,
                     method: lhs.method,
                     body: lhs.body,
                     plugins: lhs.plugins + rhs,
                     cacheSettings: lhs.cacheSettings,
                     requestPolicy: lhs.requestPolicy,
                     timeoutInterval: lhs.timeoutInterval,
                     progressHandler: lhs.progressHandler,
                     userInfo: lhs.userInfo,
                     session: lhs.session)
    }
}

#if swift(>=6.0)
extension Parameters: Sendable {}
#endif
