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

    public private(set) var address: Address
    public private(set) var header: HeaderFields
    public private(set) var method: HTTPMethod
    public private(set) var body: Body
    public private(set) var timeoutInterval: TimeInterval
    public private(set) var cacheSettings: CacheSettings?
    public private(set) var requestPolicy: URLRequest.CachePolicy
    public private(set) var queue: DelayedQueue
    public private(set) var plugins: [RequestStatePlugin]
    public private(set) var isLoggingEnabled: Bool
    public private(set) var progressHandler: ProgressHandler?
    public private(set) var session: Session
    public private(set) var encoder: JSONEncoder
    public private(set) var decoder: JSONDecoder
    public private(set) var shouldAddSlashAfterEndpoint: Bool

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

    @discardableResult
    public func set<T>(_ newValue: T, at path: WritableKeyPath<Self, T>) -> Self {
        var new = self
        new[keyPath: path] = newValue
        return new
    }

    @discardableResult
    public func modify<T>(at path: WritableKeyPath<Self, T>, _ modificator: (_ oldValue: T) -> T) -> Self {
        var new = self
        let oldValue = new[keyPath: path]
        new[keyPath: path] = modificator(oldValue)
        return new
    }
}

public extension Parameters {
    static func +(lhs: Parameters, plugin: RequestStatePlugin) -> Parameters {
        var new = lhs
        new.plugins.append(plugin)
        return new
    }

    static func +(lhs: Parameters, plugins: [RequestStatePlugin]) -> Parameters {
        if plugins.isEmpty {
            return lhs
        }

        var new = lhs
        new.plugins += plugins
        return new
    }
}
