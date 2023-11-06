import Foundation

public extension Plugins {
    final class StatusCode: Plugin {
        private let shouldIgnore200th: Bool

        /// - Parameter shouldIgnoreSuccess: ignore status code in range 200..<300
        public init(shouldIgnore200th: Bool = true) {
            self.shouldIgnore200th = shouldIgnore200th
        }

        public func verify(data: RequestResult, userInfo: UserInfo) throws {
            guard data.statusCodeInt != 200, let error = data.statusCode else {
                return
            }

            guard let kind = error.kind else {
                return
            }

            if shouldIgnore200th, kind.isSuccess {
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
