import Foundation

/// Outcome of determination whether retry is necessary.
public enum RetryResult: Sendable {
    /// Retry should be attempted immediately.
    case retry
    /// Retry should be attempted after the associated `TimeInterval`.
    case retryWithDelay(TimeInterval)
    /// Do not retry.
    case doNotRetry
    /// Do not retry due to the associated `Error`.
    case doNotRetryWithError(any Error)
}

/// Protocol that defines the mechanism of request interception and response validation.
///
/// See detailed scheme how network works:
/// ![Network scheme](https://github.com/NikSativa/SmartNetwork/raw/main/.instructions/SmartNetwork.jpg)
public protocol SmartRetrier {
    /// Determines whether to retry the network request or finish based on the result and user info.
    ///
    ///  - Important: The ``UserInfo`` contains the number of attempts made to perform a network request.
    ///
    /// - Parameters:
    ///   - result: The ``SmartResponse`` of the network request.
    ///   - address: The ``Address`` of the network request.
    ///   - parameters: The ``Parameters`` of the network request.
    ///   - userInfo: The ``UserInfo`` associated with the network request.
    /// - Returns: The decision whether to retry the network request or finish. See ``RetryResult``
    func retryOrFinish(result: SmartResponse, address: Address, parameters: Parameters, userInfo: UserInfo) -> RetryResult
}
