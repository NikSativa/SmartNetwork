import Foundation

/// An enumeration of actions that can be taken when a stop-the-line is finished.
public enum StopTheLineResult {
    /// pass over new response
    case passOver(SmartResponse)

    /// use original response
    case useOriginal

    /// ignore current response and retry request
    case retry

    /// ignore current response and retry request after the associated `TimeInterval`.
    case retryWithDelay(TimeInterval)
}

#if swift(>=6.0)
extension StopTheLineResult: Sendable {}
#endif
