import Foundation

/// An enumeration of actions that can be taken when a stop-the-line is encountered.
public enum StopTheLineAction: Hashable, SmartSendable {
    /// Stop the execution flow.
    case stopTheLine
    /// Pass over response and continue the execution flow.
    case passOver
    /// Retry the request.
    case retry
}
