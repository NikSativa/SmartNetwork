import Foundation

public extension Plugins {
    final class StatusCode: Plugin {
        #if swift(>=6.0)
        public typealias StatusCodeChecker = @Sendable (_ statusCode: Int?) -> Bool
        #else
        public typealias StatusCodeChecker = (_ statusCode: Int?) -> Bool
        #endif

        private let isIgnoring: StatusCodeChecker

        public init(isIgnoring: @escaping StatusCodeChecker) {
            self.isIgnoring = isIgnoring
        }

        /// - Parameter shouldIgnore200th: ignore status code in range `200..<300` and/or ignore `Nil`
        public init(shouldIgnore200th: Bool = true, shuoldIgnoreNil: Bool = true) {
            self.isIgnoring = { statusCode in
                if let statusCode,
                   shouldIgnore200th,
                   (200..<300).contains(statusCode) {
                    return true
                } else if shuoldIgnoreNil,
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
