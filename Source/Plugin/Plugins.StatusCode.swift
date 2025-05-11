import Foundation

public extension Plugins {
    /// A plugin that validates HTTP response status codes and throws errors for unexpected values.
    ///
    /// This plugin can be configured to ignore specific status codes or bypass validation entirely
    /// when previous errors exist or the response is non-HTTP.
    final class StatusCode: Plugin {
        #if swift(>=6.0)
        /// A closure that returns `true` if the given status code should be ignored (i.e., not treated as an error).
        public typealias StatusCodeChecker = @Sendable (_ statusCode: Int?) -> Bool
        #else
        /// A closure that returns `true` if the given status code should be ignored (i.e., not treated as an error).
        public typealias StatusCodeChecker = (_ statusCode: Int?) -> Bool
        #endif

        public let priority: PluginPriority
        private let isIgnoring: StatusCodeChecker
        private let shouldIgnorePreviousError: Bool

        /// Creates a `StatusCode` plugin with a custom status code evaluator.
        ///
        /// - Parameters:
        ///   - priority: The plugin's execution priority in the plugin chain.
        ///   - shouldIgnorePreviousError: If `true`, bypasses status code checks when an earlier error exists.
        ///   - isIgnoring: A closure that returns `true` for status codes that should be ignored (not treated as an error).
        public init(priority: PluginPriority = .statusCode,
                    shouldIgnorePreviousError: Bool = false,
                    isIgnoring: @escaping StatusCodeChecker) {
            self.priority = priority
            self.isIgnoring = isIgnoring
            self.shouldIgnorePreviousError = shouldIgnorePreviousError
        }

        /// Convenience initializer for common HTTP status code handling.
        ///
        /// - Parameters:
        ///   - shouldIgnore200th: If `true`, ignores any 2xx status code.
        ///   - shouldIgnoreNil: If `true`, ignores `nil` status codes (e.g., non-HTTP responses).
        ///   - shouldIgnorePreviousError: If `true`, bypasses this plugin if a previous error is already present.
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

        /// Verifies the HTTP response status code and throws an error if it should not be ignored.
        ///
        /// - Throws: A status code error or `.none` if the response has no status code.
        public func verify(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) throws {
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

        public func prepare(parameters: Parameters, userInfo: UserInfo, request: inout URLRequestRepresentation, session: SmartURLSession) async {}
        public func willSend(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, session: SmartURLSession) {}
        public func didReceive(parameters: Parameters, userInfo: UserInfo, request: URLRequestRepresentation, data: SmartResponse) {}
        public func didFinish(parameters: Parameters, userInfo: UserInfo, data: SmartResponse) {}
    }
}
