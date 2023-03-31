import Foundation

public extension Plugins {
    final class StatusCode: Plugin {
        private let shouldIgnore200th: Bool

        #warning("make create instead of init")
        /// - Parameter shouldIgnoreSuccess: ignore status code in range 200..<300
        public init(shouldIgnore200th: Bool = true) {
            self.shouldIgnore200th = shouldIgnore200th
        }

        public func prepare(_ parameters: Parameters, request: inout URLRequestRepresentation) {}

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
    }
}
