import Foundation
import NQueue

public typealias HeaderFields = [String: String]

public struct Parameters {
    public typealias UserInfo = [String: Any]
    public static var sharedSession: Session = URLSession.shared
    public static var defaultResponseQueue: DelayedQueue = .async(Queue.main)
    public static var shouldAddSlashAfterEndpoint: Bool = false

    public struct CacheSettings {
        public let cache: URLCache
        public let storagePolicy: URLCache.StoragePolicy
        public let queue: DelayedQueue

        public init(cache: URLCache,
                    storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                    queue: DelayedQueue = Parameters.defaultResponseQueue) {
            self.cache = cache
            self.storagePolicy = storagePolicy
            self.queue = queue
        }
    }

    public let address: Address
    public let header: HeaderFields
    public let method: HTTPMethod
    public let body: Body
    public let timeoutInterval: TimeInterval
    public let cacheSettings: CacheSettings?
    public let requestPolicy: URLRequest.CachePolicy
    public let queue: DelayedQueue
    public let plugins: [RequestStatePlugin]
    public let isLoggingEnabled: Bool
    public let progressHandler: ProgressHandler?
    public let session: Session
    public let encoder: JSONEncoder
    public let decoder: JSONDecoder
    public let shouldAddSlashAfterEndpoint: Bool

    /// used only on client side. best practice to use it to identify request in the Plugin's
    public let userInfo: UserInfo

    public init(address: Address,
                header: HeaderFields = [:],
                method: HTTPMethod = .get,
                body: Body = .empty,
                plugins: [RequestStatePlugin] = [],
                cacheSettings: CacheSettings? = nil,
                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                timeoutInterval: TimeInterval = 60,
                queue: DelayedQueue = Self.defaultResponseQueue,
                isLoggingEnabled: Bool = false,
                progressHandler: ProgressHandler? = nil,
                userInfo: UserInfo = .init(),
                session: Session = Self.sharedSession,
                encoder: JSONEncoder = .init(),
                decoder: JSONDecoder = .init(),
                shouldAddSlashAfterEndpoint: Bool = Self.shouldAddSlashAfterEndpoint) {
        self.address = address
        self.header = header
        self.method = method
        self.body = body
        self.plugins = plugins
        self.timeoutInterval = timeoutInterval
        self.cacheSettings = cacheSettings
        self.requestPolicy = requestPolicy
        self.queue = queue
        self.isLoggingEnabled = isLoggingEnabled
        self.progressHandler = progressHandler
        self.userInfo = userInfo
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.shouldAddSlashAfterEndpoint = shouldAddSlashAfterEndpoint
    }
}
