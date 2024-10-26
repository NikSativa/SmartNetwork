import Foundation

public extension Plugins {
    /// A plugin that checks the http status code of the response.
    final class StatusCode: Plugin {
        #if swift(>=6.0)
        /// The status code checker.
        public typealias StatusCodeChecker = @Sendable (_ statusCode: Int?) -> Bool
        #else
        /// The status code checker.
        public typealias StatusCodeChecker = (_ statusCode: Int?) -> Bool
        #endif

        public let priority: PluginPriority
        private let isIgnoring: StatusCodeChecker

        /// A plugin that checks the status code of the response.
        ///
        /// - Parameter isIgnoring: a closure that returns `true` if the status code should be ignored.
        public init(priority: PluginPriority = .statusCode,
                    isIgnoring: @escaping StatusCodeChecker) {
            self.priority = priority
            self.isIgnoring = isIgnoring
        }

        /// A plugin that checks the status code of the response.
        ///
        /// - Parameter shouldIgnore200th: ignore status code in range `200..<300` and/or ignore `Nil`
        public init(priority: PluginPriority = .statusCode,
                    shouldIgnore200th: Bool = true,
                    shouldIgnoreNil: Bool = true) {
            self.priority = priority
            self.isIgnoring = { statusCode in
                if let statusCode,
                   shouldIgnore200th,
                   (200..<300).contains(statusCode) {
                    return true
                } else if shouldIgnoreNil,
                          statusCode == nil {
                    return true
                }
                return false
            }
        }

        public func verify(data: RequestResult, userInfo: UserInfo) throws {
            if isIgnoring(data.statusCodeInt) {
                return
            }

            guard let error = data.statusCode else {
                return
            }

            throw error
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation) {}
        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {}
        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo) {}
        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}
    }
}
