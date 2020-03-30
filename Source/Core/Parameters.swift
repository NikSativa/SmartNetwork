import Foundation

public struct Parameters {
    public struct CacheSettings: Equatable {
        public let cache: URLCache?
        public let storagePolicy: URLCache.StoragePolicy
        public let requestPolicy: URLRequest.CachePolicy

        public init(cache: URLCache? = nil,
                    storagePolicy: URLCache.StoragePolicy = .allowedInMemoryOnly,
                    requestPolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
            self.cache = cache
            self.storagePolicy = storagePolicy
            self.requestPolicy = requestPolicy
        }
    }

    public let address: Address
    public let header: [String: String]
    public let method: HTTPMethod
    public let timeoutInterval: TimeInterval
    public let cacheSettings: CacheSettings
    public let queue: Queue
    public let plugins: [Plugin]
    public let isLoggingEnabled: Bool

    public init(address: Address,
                header: [String: String] = [:],
                method: HTTPMethod = .get,
                plugins: [Plugin] = [],
                cacheSettings: CacheSettings = .init(),
                timeoutInterval: TimeInterval = 60,
                queue: Queue = DispatchQueue.main,
                isLoggingEnabled: Bool = false) {
        self.address = address
        self.header = header
        self.method = method
        self.plugins = plugins
        self.timeoutInterval = timeoutInterval
        self.cacheSettings = cacheSettings
        self.queue = queue
        self.isLoggingEnabled = isLoggingEnabled
    }

    private init(_ original: Parameters, plugins: [Plugin]) {
        self.address = original.address
        self.header = original.header
        self.method = original.method
        self.plugins = plugins
        self.timeoutInterval = original.timeoutInterval
        self.cacheSettings = original.cacheSettings
        self.queue = original.queue
        self.isLoggingEnabled = original.isLoggingEnabled
    }
}

extension Parameters {
    public static func + (lhs: Parameters, plugin: Plugin) -> Parameters {
        return Parameters(lhs, plugins: lhs.plugins + [plugin])
    }

    public static func + (lhs: Parameters, plugin: [Plugin]) -> Parameters {
        return Parameters(lhs, plugins: lhs.plugins + plugin)
    }
}
