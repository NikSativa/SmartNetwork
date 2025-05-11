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

    /// Initializes a new Parameters object.
    public init(header: HeaderFields = [:],
                method: HTTPMethod? = .get,
                body: Body? = nil,
                plugins: [Plugin] = [],
                cacheSettings: CacheSettings? = nil,
                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                timeoutInterval: TimeInterval = SmartNetworkSettings.timeoutInterval,
                progressHandler: ProgressHandler? = nil,
                shouldIgnoreStopTheLine: Bool = false) {
        self.header = header
        self.method = method
        self.body = body
        self.plugins = plugins
        self.timeoutInterval = timeoutInterval
        self.cacheSettings = cacheSettings
        self.requestPolicy = requestPolicy
        self.progressHandler = progressHandler
        self.shouldIgnoreStopTheLine = shouldIgnoreStopTheLine
    }
}

public extension Parameters {
    /// Converts the current `Parameters` instance into a `URLRequestRepresentation` for the specified address.
    ///
    /// This method constructs a `URLRequest` using the address's URL, headers, HTTP method, body, cache policy,
    /// and timeout configuration defined in the `Parameters`. It also applies any body encoding logic if present.
    ///
    /// - Parameter address: The destination `Address` from which to derive the request URL.
    /// - Returns: A `URLRequestRepresentation` that reflects the current parameters and address.
    /// - Throws: An error if the URL cannot be created or if body encoding fails.
    func urlRequest(for address: Address) throws -> URLRequestRepresentation {
        let url = try address.url()
        var request = URLRequest(url: url,
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method?.toString()

        for item in header {
            request.addValue(item.value, forHTTPHeaderField: item.key)
        }

        try body.encode().fill(&request)

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
                     progressHandler: lhs.progressHandler)
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
                     progressHandler: lhs.progressHandler)
    }
}

#if swift(>=6.0)
extension Parameters: Sendable {}
#endif
