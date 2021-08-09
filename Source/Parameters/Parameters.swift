import Foundation
import NQueue

public typealias HeaderFields = [String: String]

public struct Parameters {
    public enum TaskKind {
        case download(progressHandler: ProgressHandler)
        case upload(progressHandler: ProgressHandler)
    }

    public struct CacheSettings {
        public let cache: URLCache
        public let storagePolicy: URLCache.StoragePolicy
        public let queue: DelayedQueue

        public init(cache: URLCache,
                    storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                    queue: DelayedQueue = .async(Queue.main)) {
            self.cache = cache
            self.storagePolicy = storagePolicy
            self.queue = queue
        }
    }

    public var address: Address
    public var header: HeaderFields
    public var method: HTTPMethod
    public var body: Body
    public var timeoutInterval: TimeInterval
    public var cacheSettings: CacheSettings?
    public var requestPolicy: URLRequest.CachePolicy
    public var queue: DelayedQueue
    public var plugins: [Plugin]
    public var isLoggingEnabled: Bool
    public var taskKind: TaskKind?
    public var session: Session

    /// used only on client side. best practice to use it to identify request in the Plugin's
    public var userInfo: [String: Any] = [:]

    public init(address: Address,
                header: HeaderFields = [:],
                method: HTTPMethod = .get,
                body: Body = .empty,
                plugins: [Plugin] = [],
                cacheSettings: CacheSettings? = nil,
                requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                timeoutInterval: TimeInterval = 60,
                queue: DelayedQueue = .async(Queue.main),
                isLoggingEnabled: Bool = false,
                taskKind: TaskKind? = nil,
                session: Session = URLSession.shared) {
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
        self.taskKind = taskKind
        self.session = session
    }
}

extension Parameters {
    public static func + (lhs: Parameters, plugin: Plugin) -> Parameters {
        var new = lhs
        new.plugins.append(plugin)
        return new
    }

    public static func + (lhs: Parameters, plugins: [Plugin]) -> Parameters {
        if plugins.isEmpty {
            return lhs
        }

        var new = lhs
        new.plugins += plugins
        return new
    }
}

extension Parameters {
    func sdkRequest() throws -> URLRequest {
        var request = URLRequest(url: try address.url(),
                                 cachePolicy: requestPolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = method.toString()

        for (key, value) in header {
            request.addValue(value, forHTTPHeaderField: key)
        }

        try body.fill(&request, isLoggingEnabled: isLoggingEnabled)
        return request
    }
}
