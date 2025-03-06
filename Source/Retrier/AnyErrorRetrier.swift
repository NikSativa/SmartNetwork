import Foundation

public struct AnyErrorRetrier: SmartRetrier {
    public let result: RetryResult
    public let attemptsCount: Int

    public init(attemptsCount: Int = 3, result: RetryResult = .doNotRetry) {
        self.attemptsCount = attemptsCount
        self.result = result.validate()
    }

    public func retryOrFinish(result: SmartResponse, address: Address, parameters: Parameters, userInfo: UserInfo) -> RetryResult {
        if userInfo.attemptsCount < attemptsCount {
            return .retry
        }
        return self.result
    }
}

private extension RetryResult {
    func validate() -> Self {
        switch self {
        case .retry,
             .retryWithDelay:
            assertionFailure("Invalid retry result: \(self). Valid options are .doNotRetry and .doNotRetryWithError")
            return .doNotRetry
        case .doNotRetry,
             .doNotRetryWithError:
            return self
        }
    }
}
