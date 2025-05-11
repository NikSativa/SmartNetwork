import Foundation

/// Represents the outcome of retry evaluation after a network request.
///
/// Used by `SmartRetrier` to indicate whether and how a failed request should be retried.
public enum RetryResult: SmartSendable {
    /// Retry should be attempted immediately without delay.
    case retry
    /// Retry should be attempted after the specified delay.
    ///
    /// - Parameter: The number of seconds to wait before retrying.
    case retryWithDelay(TimeInterval)
    /// No retry should be attempted; the request is considered complete.
    case doNotRetry
    /// No retry should be attempted due to an error, which should be propagated.
    ///
    /// - Parameter: The error that triggered the decision to stop retrying.
    case doNotRetryWithError(any Error)
}

/// Defines a retry strategy for failed or invalid network requests.
///
/// `SmartRetrier` allows network clients to inspect the response and context of a failed request and decide whether to retry it,
/// delay the retry, or propagate the failure. Integrates with `SmartRequestManager`.
///
/// See diagram: ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
public protocol SmartRetrier: SmartSendable {
    /// Determines whether the request should be retried based on the response and associated metadata.
    ///
    /// Uses the response, request configuration, and user info—including retry count—to decide the next step.
    ///
    /// - Parameters:
    ///   - result: The ``SmartResponse`` of the network request.
    ///   - address: The ``Address`` of the network request.
    ///   - parameters: The ``Parameters`` of the network request.
    ///   - userInfo: The ``UserInfo`` associated with the network request.
    /// - Returns: The decision whether to retry the network request or finish. See ``RetryResult``
    func retryOrFinish(result: SmartResponse, address: Address, parameters: Parameters, userInfo: UserInfo) -> RetryResult
}
