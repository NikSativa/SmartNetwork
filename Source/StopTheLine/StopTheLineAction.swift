import Foundation

/// An enumeration of actions that can be taken when a stop-the-line is encountered.
public enum StopTheLineAction: Hashable {
    /// Stop the execution flow.
    case stopTheLine
    /// Pass over response and continue the execution flow.
    case passOver
    /// Retry the request.
    case retry
}

#if swift(>=6.0)
extension StopTheLineAction: Sendable {}
#endif
