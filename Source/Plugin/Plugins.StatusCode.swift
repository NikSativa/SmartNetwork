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
        private let shouldIgnorePreviousError: Bool

        /// A plugin that checks the status code of the response.
        ///
        /// - Parameters:
        ///   - priority: the priority of the plugin.
        ///   - shouldIgnorePreviousError: ignore previous error tht was thrown by another plugin or the network.
        ///   - isIgnoring: a closure that returns `true` if the status code should be ignored _(not thrown as an error)_.
        public init(priority: PluginPriority = .statusCode,
                    shouldIgnorePreviousError: Bool = false,
                    isIgnoring: @escaping StatusCodeChecker) {
            self.priority = priority
            self.isIgnoring = isIgnoring
            self.shouldIgnorePreviousError = shouldIgnorePreviousError
        }

        /// A plugin that checks the status code of the response.
        ///
        /// - Parameters:
        ///   - shouldIgnore200th: ignore status code in range `200..<300` and/or ignore `Nil`
        ///   - shouldIgnoreNil: ignore `nil` status code. It happens when the response is not an HTTP response.
        ///   - shouldIgnorePreviousError: ignore previous error tht was thrown by another plugin or the network.
        public convenience init(priority: PluginPriority = .statusCode,
                                shouldIgnore200th: Bool = true,
                                shouldIgnoreNil: Bool = true,
                                shouldIgnorePreviousError: Bool = false) {
            self.init(priority: priority, shouldIgnorePreviousError: shouldIgnorePreviousError) { statusCode in
                guard let statusCode else {
                    return shouldIgnoreNil
                }

                if statusCode == 200 {
                    return true
                }

                if (200..<300).contains(statusCode) {
                    return shouldIgnore200th
                }

                return false
            }
        }

        public func verify(data: RequestResult, userInfo: UserInfo) throws {
            if !shouldIgnorePreviousError, data.error != nil {
                return
            }

            if isIgnoring(data.statusCodeInt) {
                return
            }

            if let error = data.statusCode {
                throw error
            } else {
                throw SmartNetwork.StatusCode.none
            }
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, session: SmartURLSession) {}
        public func didFinish(withData data: RequestResult, userInfo: UserInfo) {}
        public func willSend(_ parameters: Parameters, request: URLRequestRepresentation, userInfo: UserInfo, session: SmartURLSession) {}
        public func didReceive(_ parameters: Parameters, request: URLRequestRepresentation, data: RequestResult, userInfo: UserInfo) {}
    }
}
