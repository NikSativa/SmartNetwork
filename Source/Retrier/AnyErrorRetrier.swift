import Foundation

public struct AnyErrorRetrier: SmartRetrier {
    #if swift(>=6.0)
    public typealias Checker = @Sendable (any Error) -> RetryResult
    #else
    public typealias Checker = (any Error) -> RetryResult
    #endif

    public let checker: Checker
    public let attemptsCount: Int

    public init(attemptsCount: Int = 3, checker: @escaping Checker) {
        self.attemptsCount = attemptsCount
        self.checker = checker
    }

    public func retryOrFinish(result: SmartResponse, address: Address, parameters: Parameters, userInfo: UserInfo) -> RetryResult {
        guard let error = result.error, userInfo.attemptsCount < attemptsCount else {
            return .doNotRetry
        }
        return checker(error)
    }
}
