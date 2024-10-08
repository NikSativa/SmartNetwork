import Foundation
import Threading

public typealias HeaderFields = [String: String]

public struct Parameters {
    public let header: HeaderFields
    public let method: HTTPMethod?
    public let body: Body
    public let timeoutInterval: TimeInterval
    public let cacheSettings: CacheSettings?
    public let requestPolicy: URLRequest.CachePolicy
    public internal(set) var plugins: [Plugin]
    public let progressHandler: ProgressHandler?
    public let session: Session
    public let encoder: JSONEncoder
    public let decoder: JSONDecoder

    /// used only on client side. best practice to use it to identify request in the Plugin's
    public let userInfo: UserInfo

    public init(header: HeaderFields = [:],
                method: HTTPMethod? = .get,
                body: Body = .empty,
                plugins: [Plugin] = [],
                cacheSettings: CacheSettings? = nil,
                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                timeoutInterval: TimeInterval = 60,
                progressHandler: ProgressHandler? = nil,
                userInfo: UserInfo = .init(),
                session: Session = RequestSettings.sharedSession,
                encoder: JSONEncoder = .init(),
                decoder: JSONDecoder = .init()) {
        self.header = header
        self.method = method
        self.body = body
        self.plugins = plugins
        self.timeoutInterval = timeoutInterval
        self.cacheSettings = cacheSettings
        self.requestPolicy = requestPolicy
        self.progressHandler = progressHandler
        self.userInfo = userInfo
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    public func urlRequest(for address: Address) throws -> URLRequestRepresentation {
        let url = try address.url()
        var request = URLRequest(url: url,
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method?.toString()

        for (key, value) in header {
            request.setValue(value, forHTTPHeaderField: key)
        }

        try body.fill(&request, encoder: encoder)

        return request
    }
}

#if swift(>=6.0)
extension Parameters: Sendable {}
#endif
