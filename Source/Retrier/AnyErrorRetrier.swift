import Foundation

/// A retrier that triggers retries for any error using a custom error-matching closure.
///
/// `AnyErrorRetrier` is useful for defining centralized retry policies based on error inspection logic.
/// It supports a configurable maximum retry count and uses a user-provided closure to evaluate each error.
public actor AnyErrorRetrier: SmartRetrier {
    #if swift(>=6.0)
    /// Closure type that maps an error to ``RetryResult``.
    public typealias Checker = @Sendable (any Error) -> RetryResult
    #else
    /// Closure type that maps an error to ``RetryResult``.
    public typealias Checker = (any Error) -> RetryResult
    #endif

    /// The user-defined closure used to evaluate retry logic based on the encountered error.
    public let checker: Checker
    /// The maximum number of retry attempts allowed.
    public let attemptsCount: Int

    /// Creates an `AnyErrorRetrier` with a maximum number of attempts and a custom error evaluation closure.
    ///
    /// - Parameters:
    ///   - attemptsCount: The maximum number of retries allowed (default is 3).
    ///   - checker: A closure that receives an error and returns a `RetryResult`.
    public init(attemptsCount: Int = 3, checker: @escaping Checker) {
        self.attemptsCount = attemptsCount
        self.checker = checker
    }

    /// Determines whether to retry based on the current error and retry count.
    ///
    /// - Parameters:
    ///   - result: The response from the failed request.
    ///   - url: The url of the request.
    ///   - parameters: The parameters of the request.
    ///   - userInfo: Metadata including the current retry attempt count.
    /// - Returns: A `RetryResult` indicating whether the request should be retried or not.
    public func retryOrFinish(result: SmartResponse, url: SmartURL, parameters: Parameters, userInfo: UserInfo) -> RetryResult {
        guard let error = result.error, userInfo.attemptsCount < attemptsCount else {
            return .doNotRetry
        }

        return checker(error)
    }

    /// Determines whether to retry based on the current error and retry count.
    ///
    /// - Parameters:
    ///   - result: The response from the failed request.
    ///   - url: The url of the request.
    ///   - parameters: The parameters of the request.
    ///   - userInfo: Metadata including the current retry attempt count.
    /// - Returns: A `RetryResult` indicating whether the request should be retried or not.
    public func retryOrFinish(result: SmartResponse, url: URL, parameters: Parameters, userInfo: UserInfo) -> RetryResult {
        return retryOrFinish(result: result, url: .url(url), parameters: parameters, userInfo: userInfo)
    }
}
