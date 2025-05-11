import Foundation

/// Represents the possible outcomes of a stop-the-line resolution.
///
/// Used to determine how the system should proceed after an interruption or validation check in the request pipeline.
/// Each case defines a distinct strategy for continuing or retrying the request flow.
public enum StopTheLineResult: SmartSendable {
    /// Replaces the original response with a new one and proceeds.
    ///
    /// - Parameter response: The alternative `SmartResponse` to use.
    case passOver(SmartResponse)

    /// Continues using the original response without modification.
    case useOriginal

    /// Discards the current response and immediately retries the request.
    case retry

    /// Discards the current response and retries the request after a delay.
    ///
    /// - Parameter delay: The time interval to wait before retrying.
    case retryWithDelay(TimeInterval)
}
