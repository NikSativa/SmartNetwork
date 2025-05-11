import Foundation

/// A retrier that handles automatic retries for connection-related network errors.
///
/// `ConnectionErrorRetrier` evaluates whether a failed request should be retried based on the error type and the number
/// of previous attempts. It specifically checks for connection errors and allows a configurable maximum retry count.
///
public struct ConnectionErrorRetrier: SmartRetrier {
    /// The fallback result to return if retry conditions are not met.
    public let result: RetryResult
    /// The maximum number of retry attempts allowed for a connection-related failure.
    public let attemptsCount: Int

    /// Creates a new instance of `ConnectionErrorRetrier`.
    ///
    /// - Parameters:
    ///   - attemptsCount: Maximum number of retry attempts (default is 3).
    ///   - result: The default result to return if retry is not triggered (default is `.doNotRetry`).
    public init(attemptsCount: Int = 3, result: RetryResult = .doNotRetry) {
        self.attemptsCount = attemptsCount
        self.result = result.validate()
    }

    /// Determines whether to retry the request based on connection error type and attempt count.
    ///
    /// - Parameters:
    ///   - result: The response received from the request.
    ///   - address: The request address.
    ///   - parameters: The request parameters.
    ///   - userInfo: Metadata including the current attempt count.
    /// - Returns: A `RetryResult` indicating whether to retry or not.
    public func retryOrFinish(result: SmartResponse, address: Address, parameters: Parameters, userInfo: UserInfo) -> RetryResult {
        if case .connection = result.error?.requestError,
           userInfo.attemptsCount < attemptsCount {
            return .retry
        }
        return self.result
    }
}

/// Internal validation to ensure only `.doNotRetry` and `.doNotRetryWithError` are used in the retrier configuration.
private extension RetryResult {
    /// Returns a valid fallback `RetryResult`, asserting if an invalid result is provided at initialization.
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
