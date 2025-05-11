import Foundation

/// Represents control flow decisions when a stop-the-line checkpoint is triggered in the request pipeline.
///
/// Used to indicate how the system should proceed—halt execution, continue with the response, or retry the request.
public enum StopTheLineAction: Hashable, SmartSendable {
    /// Halts the request processing pipeline at the current checkpoint.
    case stopTheLine
    /// Continues processing using the current response, bypassing the checkpoint.
    case passOver
    /// Restarts the request flow from the beginning.
    case retry
}
