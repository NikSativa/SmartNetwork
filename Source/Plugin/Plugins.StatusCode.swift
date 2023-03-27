import Foundation

public extension Plugins {
    final class StatusCode: Plugin {
        private let shouldIgnore200th: Bool

        /// - Parameter shouldIgnoreSuccess: ignore status code in range 200..<300
        public init(shouldIgnore200th: Bool = true) {
            self.shouldIgnore200th = shouldIgnore200th
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation, userInfo: inout Parameters.UserInfo) {}

        public func verify(data: RequestResult, userInfo: Parameters.UserInfo) throws {
            guard let statusCode = data.statusCode else {
                return
            }

            let error = NRequest.StatusCode(code: statusCode)
            guard let kind = error.kind, kind != .success else {
                return
            }

            if shouldIgnore200th, kind.isSuccess {
                return
            }

            throw error
        }
    }
}
